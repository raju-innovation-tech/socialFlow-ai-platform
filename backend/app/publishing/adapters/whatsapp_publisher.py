from typing import Any, Dict, List, Optional
import httpx

from app.core.logging import logger
from app.models.media import MediaAsset
from app.models.social_account import SocialAccount
from app.publishing.adapters.base import BasePublishingAdapter, PublishingResult


class WhatsAppPublisher(BasePublishingAdapter):
    @property
    def platform_identifier(self) -> str:
        return "whatsapp"

    def validate_content(
        self,
        text: str,
        media_items: Optional[List[MediaAsset]] = None,
        extra_params: Optional[Dict[str, Any]] = None,
    ) -> List[str]:
        errors = []
        params = extra_params or {}

        # Explicit enforcement of Section 4.F: WhatsApp Channels & Groups are unavailable via Cloud API
        target_type = params.get("target_type", "direct_message")
        if target_type in ("channel", "group", "community"):
            errors.append(
                f"Automated publishing to WhatsApp {target_type.capitalize()}s is unavailable via official Meta Cloud API. Use manual broadcasting or approved template notifications."
            )

        if not text and not media_items and "template_name" not in params:
            errors.append("WhatsApp message must contain text, media, or an approved template.")

        if len(text) > 4096:
            errors.append(f"WhatsApp text cannot exceed 4,096 characters (current: {len(text)}).")

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
                error_code="UNSUPPORTED_CAPABILITY" if "unavailable" in errors[0] else "VALIDATION_FAILED",
                error_message="; ".join(errors),
                is_retryable=False,
            )

        params = extra_params or {}
        phone_number_id = account.platform_account_id
        recipient_phone = params.get("recipient_phone") or params.get("to") or "broadcast_recipient"

        url = f"https://graph.facebook.com/v20.0/{phone_number_id}/messages"
        headers = {
            "Authorization": f"Bearer {decrypted_token}",
            "Content-Type": "application/json",
        }

        # Build Meta Cloud API payload
        if "template_name" in params:
            payload = {
                "messaging_product": "whatsapp",
                "to": recipient_phone,
                "type": "template",
                "template": {
                    "name": params["template_name"],
                    "language": {"code": params.get("language_code", "en_US")},
                },
            }
        elif media_items:
            first_media = media_items[0]
            m_type = "image" if first_media.file_type == "image" else "video"
            payload = {
                "messaging_product": "whatsapp",
                "to": recipient_phone,
                "type": m_type,
                m_type: {
                    "link": first_media.storage_path,
                    "caption": text[:1024] if text else None,
                },
            }
        else:
            payload = {
                "messaging_product": "whatsapp",
                "to": recipient_phone,
                "type": "text",
                "text": {"preview_url": True, "body": text},
            }

        try:
            async with self.create_http_client() as client:
                res = await client.post(url, headers=headers, json=payload)

                if res.status_code == 200:
                    data = res.json()
                    messages = data.get("messages", [])
                    message_id = messages[0].get("id") if messages else ""
                    return PublishingResult(
                        success=True,
                        external_post_id=message_id,
                        external_post_url=None,  # Direct messages do not have a public web URL
                        raw_response=data,
                    )

                status_code = res.status_code
                err_data = res.json().get("error", {})
                err_msg = err_data.get("message", res.text)
                err_code = err_data.get("code")

                # Code 131047: Customer service window expired (requires template message)
                if err_code == 131047:
                    return PublishingResult(
                        success=False,
                        error_code="WHATSAPP_WINDOW_EXPIRED",
                        error_message="Customer service 24-hour window has expired. An approved Meta message template is required.",
                        is_retryable=False,
                        raw_response={"error": err_data},
                    )

                is_retryable = status_code in (429, 500, 502, 503, 504) or err_code == 130429
                logger.error("WhatsApp publish failed [%d]: %s", status_code, err_msg)
                return PublishingResult(
                    success=False,
                    error_code=f"WHATSAPP_ERROR_{err_code or status_code}",
                    error_message=f"WhatsApp Cloud API: {err_msg[:200]}",
                    is_retryable=is_retryable,
                    raw_response={"error": err_data, "status_code": status_code},
                )

        except httpx.RequestError as exc:
            logger.error("WhatsApp network error: %s", exc)
            return PublishingResult(
                success=False,
                error_code="NETWORK_ERROR",
                error_message=str(exc),
                is_retryable=True,
            )

