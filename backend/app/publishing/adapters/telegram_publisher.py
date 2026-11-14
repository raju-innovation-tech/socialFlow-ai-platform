from typing import Any, Dict, List, Optional
import httpx

from app.core.logging import logger
from app.models.media import MediaAsset
from app.models.social_account import SocialAccount
from app.publishing.adapters.base import BasePublishingAdapter, PublishingResult


class TelegramPublisher(BasePublishingAdapter):
    @property
    def platform_identifier(self) -> str:
        return "telegram"

    def validate_content(
        self,
        text: str,
        media_items: Optional[List[MediaAsset]] = None,
        extra_params: Optional[Dict[str, Any]] = None,
    ) -> List[str]:
        errors = []
        if not text and not media_items:
            errors.append("Telegram post must contain text or media.")
        if media_items and len(text) > 1024:
            errors.append(f"Telegram media caption limit is 1,024 characters (current: {len(text)}).")
        elif len(text) > 4096:
            errors.append(f"Telegram text message limit is 4,096 characters (current: {len(text)}).")
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

        params = extra_params or {}
        chat_id = params.get("chat_id") or account.platform_account_id
        if not chat_id:
            return PublishingResult(
                success=False,
                error_code="MISSING_TARGET_CHAT",
                error_message="Telegram requires a target channel or group ID (e.g. @my_channel or -100...).",
                is_retryable=False,
            )

        base_url = f"https://api.telegram.org/bot{decrypted_token}"

        try:
            async with self.create_http_client() as client:
                # 1. Video Message
                if media_items and any(m.file_type == "video" for m in media_items):
                    video_item = next(m for m in media_items if m.file_type == "video")
                    url = f"{base_url}/sendVideo"
                    payload = {
                        "chat_id": chat_id,
                        "video": video_item.storage_path,
                        "caption": text,
                        "parse_mode": "HTML",
                    }
                    res = await client.post(url, json=payload)

                # 2. Photo Message
                elif media_items and any(m.file_type == "image" for m in media_items):
                    photo_item = media_items[0]
                    url = f"{base_url}/sendPhoto"
                    payload = {
                        "chat_id": chat_id,
                        "photo": photo_item.storage_path,
                        "caption": text,
                        "parse_mode": "HTML",
                    }
                    res = await client.post(url, json=payload)

                # 3. Standard Text Message
                else:
                    url = f"{base_url}/sendMessage"
                    payload = {
                        "chat_id": chat_id,
                        "text": text,
                        "parse_mode": "HTML",
                        "disable_web_page_preview": False,
                    }
                    res = await client.post(url, json=payload)

                if res.status_code == 200 and res.json().get("ok") is True:
                    data = res.json()
                    res_obj = data.get("result", {})
                    msg_id = str(res_obj.get("message_id", ""))
                    chat_username = res_obj.get("chat", {}).get("username")
                    post_url = f"https://t.me/{chat_username}/{msg_id}" if chat_username else None
                    return PublishingResult(
                        success=True,
                        external_post_id=msg_id,
                        external_post_url=post_url,
                        raw_response=data,
                    )

                data = res.json() if res.headers.get("content-type", "").startswith("application/json") else {}
                err_code = data.get("error_code", res.status_code)
                desc = data.get("description", res.text)

                # Check if bot lacks administrator privileges
                if "administrator" in desc.lower() or "not enough rights" in desc.lower() or err_code == 403:
                    return PublishingResult(
                        success=False,
                        error_code="TELEGRAM_PERMISSION_DENIED",
                        error_message=f"Telegram Bot lacks permission: {desc}",
                        is_retryable=False,
                        raw_response=data,
                    )

                is_retryable = err_code == 429 or res.status_code >= 500
                logger.error("Telegram publish failed [%s]: %s", err_code, desc)

                return PublishingResult(
                    success=False,
                    error_code=f"TELEGRAM_ERROR_{err_code}",
                    error_message=f"Telegram API: {desc[:200]}",
                    is_retryable=is_retryable,
                    raw_response=data,
                )

        except httpx.RequestError as exc:
            logger.error("Telegram network error: %s", exc)
            return PublishingResult(
                success=False,
                error_code="NETWORK_ERROR",
                error_message=str(exc),
                is_retryable=True,
            )

