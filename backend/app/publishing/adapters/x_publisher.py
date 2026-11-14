from typing import Any, Dict, List, Optional
import httpx

from app.core.logging import logger
from app.models.media import MediaAsset
from app.models.social_account import SocialAccount
from app.publishing.adapters.base import BasePublishingAdapter, PublishingResult


class XPublisher(BasePublishingAdapter):
    @property
    def platform_identifier(self) -> str:
        return "x"

    def validate_content(
        self,
        text: str,
        media_items: Optional[List[MediaAsset]] = None,
        extra_params: Optional[Dict[str, Any]] = None,
    ) -> List[str]:
        errors = []
        if not text and not media_items:
            errors.append("Post must contain text or media.")
        if len(text) > 280:
            errors.append(f"X (Twitter) character limit is 280 (current: {len(text)}).")
        if media_items and len(media_items) > 4:
            errors.append(f"X allows a maximum of 4 images per tweet (current: {len(media_items)}).")
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

        headers = {
            "Authorization": f"Bearer {decrypted_token}",
            "Content-Type": "application/json",
        }

        payload: Dict[str, Any] = {"text": text}

        # In production with uploaded media IDs:
        if extra_params and "media_ids" in extra_params:
            payload["media"] = {"media_ids": extra_params["media_ids"]}

        try:
            async with self.create_http_client() as client:
                res = await client.post(
                    "https://api.twitter.com/2/tweets",
                    headers=headers,
                    json=payload,
                )

                if res.status_code in (200, 201):
                    data = res.json()
                    tweet_data = data.get("data", {})
                    tweet_id = tweet_data.get("id", "")
                    handle = account.platform_account_id or "i"
                    tweet_url = f"https://x.com/{handle}/status/{tweet_id}" if tweet_id else None
                    return PublishingResult(
                        success=True,
                        external_post_id=str(tweet_id),
                        external_post_url=tweet_url,
                        raw_response=data,
                    )

                status_code = res.status_code
                err_data = res.json() if res.headers.get("content-type", "").startswith("application/json") else {}
                detail = err_data.get("detail", res.text)
                title = err_data.get("title", f"HTTP_{status_code}")

                is_retryable = status_code in (429, 500, 502, 503, 504)
                logger.error("X tweet publish failed [%d]: %s", status_code, detail)

                return PublishingResult(
                    success=False,
                    error_code=f"X_API_ERROR_{status_code}",
                    error_message=f"X API: {title} - {detail[:180]}",
                    is_retryable=is_retryable,
                    raw_response={"error": err_data, "status_code": status_code},
                )

        except httpx.RequestError as exc:
            logger.error("X network error: %s", exc)
            return PublishingResult(
                success=False,
                error_code="NETWORK_ERROR",
                error_message=str(exc),
                is_retryable=True,
            )

