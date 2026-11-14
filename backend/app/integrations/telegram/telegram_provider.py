from typing import Any, Dict, List, Optional
import httpx

from app.core.config import settings
from app.integrations.base.base_provider import BasePlatformProvider
from app.integrations.base.capability_models import (
    AccountProfile,
    CapabilityCategory,
    CapabilityStatus,
    DiscoveredChannel,
    PlatformCapabilityModel,
    TokenBundle,
)
from app.integrations.base.integration_exceptions import (
    AccountNotEligibleException,
    OAuthTokenExchangeException,
    PlatformRateLimitException,
    PlatformServiceUnavailableException,
)


class TelegramProvider(BasePlatformProvider):
    API_BASE = "https://api.telegram.org"

    @property
    def platform_identifier(self) -> str:
        return "telegram"

    @property
    def platform_name(self) -> str:
        return "Telegram Channels & Groups"

    def get_capabilities(self) -> List[PlatformCapabilityModel]:
        return [
            PlatformCapabilityModel(
                code="bot_connection",
                name="Telegram Bot Authentication",
                category=CapabilityCategory.AUTHENTICATION,
                status=CapabilityStatus.SUPPORTED,
                notes="Secure token validation via official Telegram Bot API getMe method",
                doc_url="https://core.telegram.org/bots/api#getme",
            ),
            PlatformCapabilityModel(
                code="channel_admin_required",
                name="Channel Administrator Requirement",
                category=CapabilityCategory.AUTHENTICATION,
                status=CapabilityStatus.REQUIRES_PERMISSION,
                notes="The bot must be added as an Administrator to the target Channel or Group with 'can_post_messages' permission",
                doc_url="https://core.telegram.org/bots/api#getchatmember",
            ),
            PlatformCapabilityModel(
                code="publish_message",
                name="Broadcast Markdown / HTML Message",
                category=CapabilityCategory.PUBLISHING,
                status=CapabilityStatus.SUPPORTED,
                notes="Publishes formatted messages via sendMessage endpoint",
            ),
            PlatformCapabilityModel(
                code="publish_photo",
                name="Send Single & Grouped Photos",
                category=CapabilityCategory.MEDIA,
                status=CapabilityStatus.SUPPORTED,
                notes="Supported via sendPhoto and sendMediaGroup",
            ),
            PlatformCapabilityModel(
                code="publish_video",
                name="Send Video & Documents",
                category=CapabilityCategory.MEDIA,
                status=CapabilityStatus.SUPPORTED,
                notes="Supported via sendVideo and sendDocument",
            ),
            PlatformCapabilityModel(
                code="publish_polls",
                name="Interactive Telegram Polls",
                category=CapabilityCategory.PUBLISHING,
                status=CapabilityStatus.SUPPORTED,
                notes="Supported via sendPoll with multiple choice and quiz options",
            ),
            PlatformCapabilityModel(
                code="arbitrary_user_chat",
                name="Unsolicited Direct User Messaging",
                category=CapabilityCategory.COMMUNITY,
                status=CapabilityStatus.UNAVAILABLE,
                notes="Telegram anti-spam policy prohibits bots from messaging arbitrary users who have not initiated conversation via /start",
            ),
        ]

    def get_authorization_url(
        self,
        workspace_id: str,
        redirect_uri: str,
        state_token: str,
        code_verifier: Optional[str] = None,
    ) -> str:
        # Telegram connects directly through Bot Token entry rather than 3-legged web OAuth
        return f"/social-accounts/connect?platform=telegram&state={state_token}"

    async def exchange_code_for_token(
        self,
        code: str,
        redirect_uri: str,
        code_verifier: Optional[str] = None,
    ) -> TokenBundle:
        # For Telegram, 'code' carries the bot token provided in the secure configuration modal
        bot_token = code.strip()
        is_valid = await self.validate_token(bot_token)
        if not is_valid:
            raise OAuthTokenExchangeException(
                self.platform_identifier,
                "Invalid Telegram Bot Token. Please verify the token copied from @BotFather.",
            )
        return TokenBundle(
            access_token=bot_token,
            expires_in=None,  # Telegram bot tokens do not expire unless revoked in BotFather
            scopes=["bot_api"],
            raw_response={"token_type": "telegram_bot_token"},
        )

    async def fetch_profile(
        self,
        token: str,
        account_id: Optional[str] = None,
    ) -> AccountProfile:
        """Fetch bot info via getMe."""
        url = f"{self.API_BASE}/bot{token}/getMe"
        async with self.create_http_client() as client:
            try:
                res = await client.get(url)
                if res.status_code == 429:
                    raise PlatformRateLimitException(self.platform_identifier)
                if res.status_code != 200:
                    raise OAuthTokenExchangeException(self.platform_identifier, res.text)

                data = res.json()
                if not data.get("ok"):
                    raise OAuthTokenExchangeException(self.platform_identifier, data.get("description", "Failed to validate bot"))

                result = data["result"]
                bot_id = str(result["id"])
                username = f"@{result['username']}"
                first_name = result.get("first_name", "Telegram Bot")

                return AccountProfile(
                    platform_account_id=bot_id,
                    username=username,
                    display_name=first_name,
                    account_type="bot",
                    profile_image_url=None,
                    follower_count=0,
                    metadata=result,
                )
            except httpx.RequestError as e:
                raise PlatformServiceUnavailableException(self.platform_identifier, str(e))

    async def validate_channel_admin(
        self,
        bot_token: str,
        chat_id: str,
    ) -> Dict[str, Any]:
        """Verify bot is an administrator in the target channel or supergroup."""
        profile = await self.fetch_profile(bot_token)
        bot_user_id = profile.platform_account_id

        # 1. Fetch Chat Info
        chat_url = f"{self.API_BASE}/bot{bot_token}/getChat?chat_id={chat_id}"
        member_url = f"{self.API_BASE}/bot{bot_token}/getChatMember?chat_id={chat_id}&user_id={bot_user_id}"

        async with self.create_http_client() as client:
            try:
                chat_res = await client.get(chat_url)
                if chat_res.status_code != 200:
                    raise AccountNotEligibleException(
                        self.platform_identifier,
                        f"Cannot find Telegram chat '{chat_id}'. Ensure the bot is added as a member.",
                    )
                chat_data = chat_res.json().get("result", {})

                # 2. Check Admin Status
                member_res = await client.get(member_url)
                if member_res.status_code != 200:
                    raise AccountNotEligibleException(
                        self.platform_identifier,
                        f"Bot is not a member of chat '{chat_id}'.",
                    )
                member_data = member_res.json().get("result", {})
                status = member_data.get("status", "")

                if status not in ("administrator", "creator"):
                    raise AccountNotEligibleException(
                        self.platform_identifier,
                        f"Bot has role '{status}' in chat '{chat_id}'. Bot must be elevated to Administrator with 'can_post_messages' permission.",
                    )

                return {
                    "chat_id": str(chat_data.get("id")),
                    "title": chat_data.get("title") or chat_data.get("username", "Telegram Channel"),
                    "type": chat_data.get("type", "channel"),
                    "can_post_messages": member_data.get("can_post_messages", True),
                }
            except httpx.RequestError as e:
                raise PlatformServiceUnavailableException(self.platform_identifier, str(e))

    async def validate_token(self, token: str) -> bool:
        url = f"{self.API_BASE}/bot{token}/getMe"
        async with self.create_http_client() as client:
            try:
                res = await client.get(url)
                if res.status_code == 200:
                    return bool(res.json().get("ok"))
                return False
            except Exception:
                return False

