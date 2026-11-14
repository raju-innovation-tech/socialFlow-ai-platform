from typing import Any, Dict, List, Optional
import httpx

from app.core.logging import logger
from app.models.media import MediaAsset
from app.models.social_account import SocialAccount
from app.publishing.adapters.base import BasePublishingAdapter, PublishingResult


class FacebookPublisher(BasePublishingAdapter):
    @property
    def platform_identifier(self) -> str:
        return "facebook"

    def validate_content(
        self,
        text: str,
        media_items: Optional[List[MediaAsset]] = None,
        extra_params: Optional[Dict[str, Any]] = None,
    ) -> List[str]:
        errors = []
        if not text and not media_items:
            errors.append("Facebook Page post must contain text or media.")
        if len(text) > 63206:
            errors.append(f"Facebook character limit is 63,206 (current: {len(text)}).")
        if media_items and len(media_items) > 10:
            errors.append(f"Facebook supports up to 10 photos per post (current: {len(media_items)}).")
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

        page_id = account.platform_account_id
        base_graph_url = "https://graph.facebook.com/v20.0"

        try:
            async with self.create_http_client() as client:
                # 1. Video post
                if media_items and any(m.file_type == "video" for m in media_items):
                    video_item = next(m for m in media_items if m.file_type == "video")
                    url = f"{base_graph_url}/{page_id}/videos"
                    data = {
                        "description": text,
                        "access_token": decrypted_token,
                        "file_url": video_item.storage_path,
                    }
                    res = await client.post(url, data=data)

                # 2. Photo post
                elif media_items and any(m.file_type == "image" for m in media_items):
                    photo_item = media_items[0]
                    url = f"{base_graph_url}/{page_id}/photos"
                    data = {
                        "caption": text,
                        "access_token": decrypted_token,
                        "url": photo_item.storage_path,
                    }
                    res = await client.post(url, data=data)

                # 3. Standard text feed post
                else:
                    url = f"{base_graph_url}/{page_id}/feed"
                    data = {
                        "message": text,
                        "access_token": decrypted_token,
                    }
                    res = await client.post(url, data=data)

                if res.status_code == 200:
                    res_data = res.json()
                    post_id = res_data.get("id") or res_data.get("post_id", "")
                    post_url = f"https://www.facebook.com/{post_id}" if post_id else None
                    return PublishingResult(
                        success=True,
                        external_post_id=str(post_id),
                        external_post_url=post_url,
                        raw_response=res_data,
                    )

                status_code = res.status_code
                error_data = res.json().get("error", {}) if res.headers.get("content-type", "").startswith("application/json") else {}
                error_msg = error_data.get("message", res.text)
                error_code = error_data.get("code")

                # Rate limiting or temporary server error is retryable
                is_retryable = status_code in (429, 500, 502, 503, 504) or error_code in (1, 2, 4, 17, 32, 613)

                logger.error("Facebook publish failed [%d]: %s", status_code, error_msg)
                return PublishingResult(
                    success=False,
                    error_code=f"FACEBOOK_ERROR_{error_code or status_code}",
                    error_message=f"Facebook API: {error_msg[:200]}",
                    is_retryable=is_retryable,
                    raw_response={"error": error_data, "status_code": status_code},
                )

        except httpx.RequestError as exc:
            logger.error("Facebook network request error: %s", exc)
            return PublishingResult(
                success=False,
                error_code="NETWORK_ERROR",
                error_message=str(exc),
                is_retryable=True,
            )

