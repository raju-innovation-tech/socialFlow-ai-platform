import asyncio
from typing import Any, Dict, List, Optional
import httpx

from app.core.logging import logger
from app.models.media import MediaAsset
from app.models.social_account import SocialAccount
from app.publishing.adapters.base import BasePublishingAdapter, PublishingResult


class InstagramPublisher(BasePublishingAdapter):
    @property
    def platform_identifier(self) -> str:
        return "instagram"

    def validate_content(
        self,
        text: str,
        media_items: Optional[List[MediaAsset]] = None,
        extra_params: Optional[Dict[str, Any]] = None,
    ) -> List[str]:
        errors = []
        if not media_items:
            errors.append("Instagram requires at least one image or video attachment (text-only posts are unsupported).")
        if len(text) > 2200:
            errors.append(f"Instagram caption limit is 2,200 characters (current: {len(text)}).")
        if media_items and len(media_items) > 10:
            errors.append(f"Instagram supports up to 10 media items in a carousel (current: {len(media_items)}).")
        return errors

    async def publish(
        self,
        account: SocialAccount,
        decrypted_token: str,
        text: str,
        media_items: Optional[List[MediaAsset]] = None,
        extra_params: Optional[Dict[str, Any]] = None,
    ) -> PublishingResult:
        errors = self.validate_content(text, media_items, extra_params)
        if errors:
            return PublishingResult(
                success=False,
                error_code="VALIDATION_FAILED",
                error_message="; ".join(errors),
                is_retryable=False,
            )

        ig_user_id = account.platform_account_id
        base_graph_url = "https://graph.facebook.com/v20.0"

        try:
            async with self.create_http_client() as client:
                primary_media = media_items[0]
                is_video = primary_media.file_type == "video"

                # Step 1: Create Media Container
                create_url = f"{base_graph_url}/{ig_user_id}/media"
                create_data = {
                    "access_token": decrypted_token,
                    "caption": text,
                }

                if is_video:
                    create_data["media_type"] = "REELS"
                    create_data["video_url"] = primary_media.storage_path
                else:
                    create_data["image_url"] = primary_media.storage_path

                container_res = await client.post(create_url, data=create_data)
                if container_res.status_code != 200:
                    err_info = container_res.json().get("error", {})
                    msg = err_info.get("message", container_res.text)
                    code = err_info.get("code")
                    logger.error("Instagram container creation failed: %s", msg)
                    return PublishingResult(
                        success=False,
                        error_code=f"INSTAGRAM_CONTAINER_ERROR_{code}",
                        error_message=f"Instagram container creation: {msg[:200]}",
                        is_retryable=container_res.status_code in (429, 500, 502, 503, 504),
                    )

                creation_id = container_res.json().get("id")

                # Step 2: If video, wait for processing status
                if is_video:
                    for _ in range(6):  # Wait up to ~12 seconds
                        await asyncio.sleep(2)
                        status_res = await client.get(
                            f"{base_graph_url}/{creation_id}",
                            params={"fields": "status_code", "access_token": decrypted_token},
                        )
                        if status_res.status_code == 200:
                            status_code = status_res.json().get("status_code")
                            if status_code == "FINISHED":
                                break
                            elif status_code == "ERROR":
                                return PublishingResult(
                                    success=False,
                                    error_code="VIDEO_PROCESSING_FAILED",
                                    error_message="Instagram video transcode/processing failed.",
                                    is_retryable=False,
                                )

                # Step 3: Publish Container
                publish_url = f"{base_graph_url}/{ig_user_id}/media_publish"
                publish_res = await client.post(
                    publish_url,
                    data={"creation_id": creation_id, "access_token": decrypted_token},
                )

                if publish_res.status_code == 200:
                    pub_data = publish_res.json()
                    media_id = pub_data.get("id", "")
                    post_url = f"https://www.instagram.com/p/{media_id}/" if media_id else None
                    return PublishingResult(
                        success=True,
                        external_post_id=str(media_id),
                        external_post_url=post_url,
                        raw_response=pub_data,
                    )

                pub_err = publish_res.json().get("error", {})
                return PublishingResult(
                    success=False,
                    error_code=f"INSTAGRAM_PUBLISH_ERROR_{pub_err.get('code')}",
                    error_message=f"Instagram publish failed: {pub_err.get('message', publish_res.text)[:200]}",
                    is_retryable=publish_res.status_code in (429, 500, 502, 503, 504),
                )

        except httpx.RequestError as exc:
            logger.error("Instagram network request error: %s", exc)
            return PublishingResult(
                success=False,
                error_code="NETWORK_ERROR",
                error_message=str(exc),
                is_retryable=True,
            )

