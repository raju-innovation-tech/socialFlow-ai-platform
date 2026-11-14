from typing import Any, Dict, List, Optional
import httpx

from app.core.logging import logger
from app.models.media import MediaAsset
from app.models.social_account import SocialAccount
from app.publishing.adapters.base import BasePublishingAdapter, PublishingResult


class LinkedInPublisher(BasePublishingAdapter):
    @property
    def platform_identifier(self) -> str:
        return "linkedin"

    def validate_content(
        self,
        text: str,
        media_items: Optional[List[MediaAsset]] = None,
        extra_params: Optional[Dict[str, Any]] = None,
    ) -> List[str]:
        errors = []
        if not text and not media_items:
            errors.append("LinkedIn post must contain text or media.")
        if len(text) > 3000:
            errors.append(f"LinkedIn character limit is 3,000 (current: {len(text)}).")
        if media_items and len(media_items) > 9:
            errors.append(f"LinkedIn supports up to 9 media attachments (current: {len(media_items)}).")
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

        # Build author URN
        if account.account_type in ("organization", "page", "company"):
            author_urn = f"urn:li:organization:{account.platform_account_id}"
        else:
            author_urn = f"urn:li:person:{account.platform_account_id}"

        headers = {
            "Authorization": f"Bearer {decrypted_token}",
            "X-Restli-Protocol-Version": "2.0.0",
            "LinkedIn-Version": "202401",
            "Content-Type": "application/json",
        }

        # Structure UGC post payload
        share_content: Dict[str, Any] = {
            "shareCommentary": {"text": text},
            "shareMediaCategory": "NONE",
        }

        # If media items present, incorporate media metadata
        if media_items:
            media_attachments = []
            for item in media_items:
                media_attachments.append({
                    "status": "READY",
                    "description": {"text": item.file_name},
                    "title": {"text": item.file_name},
                })
            share_content["shareMediaCategory"] = "IMAGE" if media_items[0].file_type == "image" else "VIDEO"
            share_content["media"] = media_attachments

        payload = {
            "author": author_urn,
            "lifecycleState": "PUBLISHED",
            "specificContent": {
                "com.linkedin.ugc.ShareContent": share_content
            },
            "visibility": {
                "com.linkedin.ugc.MemberNetworkVisibility": "PUBLIC"
            },
        }

        try:
            async with self.create_http_client() as client:
                res = await client.post(
                    "https://api.linkedin.com/v2/ugcPosts",
                    headers=headers,
                    json=payload,
                )

                if res.status_code in (200, 201):
                    data = res.json()
                    post_urn = data.get("id", "")
                    post_url = f"https://www.linkedin.com/feed/update/{post_urn}" if post_urn else None
                    return PublishingResult(
                        success=True,
                        external_post_id=post_urn,
                        external_post_url=post_url,
                        raw_response=data,
                    )

                status_code = res.status_code
                error_text = res.text
                is_retryable = status_code in (429, 500, 502, 503, 504)
                logger.error("LinkedIn publish failed [%d]: %s", status_code, error_text)

                return PublishingResult(
                    success=False,
                    error_code=f"LINKEDIN_HTTP_{status_code}",
                    error_message=f"LinkedIn API error: {error_text[:200]}",
                    is_retryable=is_retryable,
                    raw_response={"status_code": status_code, "body": error_text},
                )

        except httpx.RequestError as exc:
            logger.error("LinkedIn network request error: %s", exc)
            return PublishingResult(
                success=False,
                error_code="NETWORK_ERROR",
                error_message=str(exc),
                is_retryable=True,
            )

