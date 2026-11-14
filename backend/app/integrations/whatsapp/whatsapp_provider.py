import urllib.parse
from typing import Any, Dict, List, Optional
import httpx

from app.core.config import settings
from app.integrations.base.base_provider import BasePlatformProvider
from app.integrations.base.capability_models import (
    AccountProfile,
    CapabilityCategory,
    CapabilityStatus,
    PlatformCapabilityModel,
    TokenBundle,
)
from app.integrations.base.integration_exceptions import (
    OAuthTokenExchangeException,
    PlatformRateLimitException,
    PlatformServiceUnavailableException,
)


class WhatsAppProvider(BasePlatformProvider):
    GRAPH_BASE = "https://graph.facebook.com/v20.0"

    @property
    def platform_identifier(self) -> str:
        return "whatsapp"

    @property
    def platform_name(self) -> str:
        return "WhatsApp Business Platform"

    def get_capabilities(self) -> List[PlatformCapabilityModel]:
        return [
            PlatformCapabilityModel(
                code="waba_connection",
                name="WhatsApp Business Account (WABA)",
                category=CapabilityCategory.AUTHENTICATION,
                status=CapabilityStatus.SUPPORTED,
                notes="Official Meta Cloud API integration using verified WABA ID and Phone Number ID",
                doc_url="https://developers.facebook.com/docs/whatsapp/cloud-api",
            ),
            PlatformCapabilityModel(
                code="template_messaging",
                name="Approved Template Notifications",
                category=CapabilityCategory.PUBLISHING,
                status=CapabilityStatus.SUPPORTED,
                notes="Publish transactional and marketing messages via pre-approved Meta message templates",
            ),
            PlatformCapabilityModel(
                code="media_messages",
                name="Image, Video & Document Attachments",
                category=CapabilityCategory.MEDIA,
                status=CapabilityStatus.SUPPORTED,
                notes="Supported via Meta WhatsApp Media endpoint upload and URL referencing",
            ),
            PlatformCapabilityModel(
                code="webhooks_status",
                name="Delivery Status Webhooks",
                category=CapabilityCategory.WEBHOOKS,
                status=CapabilityStatus.SUPPORTED,
                notes="Real-time delivery receipts (sent, delivered, read, failed) via Meta Webhooks",
            ),
            # CRITICAL REALITY RESTRICTIONS
            PlatformCapabilityModel(
                code="whatsapp_channels",
                name="WhatsApp Channels Automated Publishing",
                category=CapabilityCategory.PUBLISHING,
                status=CapabilityStatus.UNAVAILABLE,
                notes="Official Meta Cloud API does NOT support third-party SaaS automated publishing to WhatsApp Channels. Manual publishing inside WhatsApp App is required.",
                doc_url="https://developers.facebook.com/docs/whatsapp",
            ),
            PlatformCapabilityModel(
                code="whatsapp_groups",
                name="WhatsApp Groups Automated Broadcast",
                category=CapabilityCategory.COMMUNITY,
                status=CapabilityStatus.UNAVAILABLE,
                notes="Meta Cloud API prohibits automated group messaging. Group automation tools rely on banned scraping/web-automation which SocialFlow AI strictly rejects.",
            ),
            PlatformCapabilityModel(
                code="whatsapp_communities",
                name="WhatsApp Communities Broadcast",
                category=CapabilityCategory.COMMUNITY,
                status=CapabilityStatus.MANUAL_ONLY,
                notes="Community announcements must be posted manually by Community Admins within the official WhatsApp client.",
            ),
        ]

    def get_authorization_url(
        self,
        workspace_id: str,
        redirect_uri: str,
        state_token: str,
        code_verifier: Optional[str] = None,
    ) -> str:
        # WhatsApp Cloud API uses Meta Embedded Signup or direct WABA ID & Permanent System User token configuration
        params = {
            "client_id": settings.META_APP_ID,
            "redirect_uri": redirect_uri,
            "state": state_token,
            "scope": "whatsapp_business_management,whatsapp_business_messaging",
            "response_type": "code",
        }
        return f"https://www.facebook.com/v20.0/dialog/oauth?{urllib.parse.urlencode(params)}"

    async def exchange_code_for_token(
        self,
        code: str,
        redirect_uri: str,
        code_verifier: Optional[str] = None,
    ) -> TokenBundle:
        params = {
            "client_id": settings.META_APP_ID,
            "client_secret": settings.META_APP_SECRET,
            "redirect_uri": redirect_uri,
            "code": code,
        }
        async with self.create_http_client() as client:
            try:
                res = await client.get(f"{self.GRAPH_BASE}/oauth/access_token", params=params)
                if res.status_code == 429:
                    raise PlatformRateLimitException(self.platform_identifier)
                if res.status_code != 200:
                    raise OAuthTokenExchangeException(self.platform_identifier, res.text)
                body = res.json()
                return TokenBundle(
                    access_token=body["access_token"],
                    expires_in=body.get("expires_in", 5184000),
                    scopes=["whatsapp_business_management", "whatsapp_business_messaging"],
                    raw_response=body,
                )
            except httpx.RequestError as e:
                raise PlatformServiceUnavailableException(self.platform_identifier, str(e))

    async def fetch_profile(
        self,
        token: str,
        account_id: Optional[str] = None,
    ) -> AccountProfile:
        """Fetch WhatsApp Business phone number details."""
        target = account_id if account_id else "me"
        headers = {"Authorization": f"Bearer {token}"}
        params = {"fields": "id,verified_name,display_phone_number,quality_rating"}

        async with self.create_http_client() as client:
            try:
                res = await client.get(f"{self.GRAPH_BASE}/{target}", headers=headers, params=params)
                if res.status_code == 429:
                    raise PlatformRateLimitException(self.platform_identifier)
                if res.status_code != 200:
                    raise OAuthTokenExchangeException(self.platform_identifier, res.text)

                data = res.json()
                phone = data.get("display_phone_number") or data.get("id")
                name = data.get("verified_name") or f"WhatsApp Business ({phone})"

                return AccountProfile(
                    platform_account_id=data["id"],
                    username=phone,
                    display_name=name,
                    account_type="business",
                    profile_image_url=None,
                    follower_count=0,
                    metadata=data,
                )
            except httpx.RequestError as e:
                raise PlatformServiceUnavailableException(self.platform_identifier, str(e))

    async def validate_token(self, token: str) -> bool:
        headers = {"Authorization": f"Bearer {token}"}
        async with self.create_http_client() as client:
            try:
                res = await client.get(f"{self.GRAPH_BASE}/me", headers=headers)
                return res.status_code == 200
            except Exception:
                return False

    def verify_webhook(self, mode: str, verify_token: str, challenge: str) -> Optional[str]:
        """Verify Meta Webhook subscription verification request."""
        if mode == "subscribe" and verify_token == settings.WHATSAPP_WEBHOOK_VERIFY_TOKEN:
            return challenge
        return None
