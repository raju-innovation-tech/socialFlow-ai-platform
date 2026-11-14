import urllib.parse
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


class InstagramProvider(BasePlatformProvider):
    GRAPH_BASE = "https://graph.facebook.com/v20.0"
    OAUTH_DIALOG_URL = "https://www.facebook.com/v20.0/dialog/oauth"

    DEFAULT_SCOPES = [
        "public_profile",
        "email",
        "pages_show_list",
        "pages_read_engagement",
        "instagram_basic",
        "instagram_content_publish",
        "instagram_manage_insights",
    ]

    @property
    def platform_identifier(self) -> str:
        return "instagram"

    @property
    def platform_name(self) -> str:
        return "Instagram Professional"

    def get_capabilities(self) -> List[PlatformCapabilityModel]:
        return [
            PlatformCapabilityModel(
                code="connect_business_creator",
                name="Connect Professional Account",
                category=CapabilityCategory.AUTHENTICATION,
                status=CapabilityStatus.SUPPORTED,
                notes="Eligible for Instagram Business and Creator accounts linked to a Facebook Page",
                doc_url="https://developers.facebook.com/docs/instagram-platform/instagram-graph-api",
            ),
            PlatformCapabilityModel(
                code="personal_account_support",
                name="Personal Instagram Accounts",
                category=CapabilityCategory.AUTHENTICATION,
                status=CapabilityStatus.UNAVAILABLE,
                notes="Meta Instagram Graph API does NOT support personal Instagram accounts",
            ),
            PlatformCapabilityModel(
                code="publish_photo",
                name="Publish Feed Photo",
                category=CapabilityCategory.MEDIA,
                status=CapabilityStatus.SUPPORTED,
                notes="Container API flow: create photo container then media_publish",
            ),
            PlatformCapabilityModel(
                code="publish_carousel",
                name="Publish Multi-Image Carousel",
                category=CapabilityCategory.MEDIA,
                status=CapabilityStatus.SUPPORTED,
                notes="Supported for up to 10 images or videos in carousel container",
            ),
            PlatformCapabilityModel(
                code="publish_reels",
                name="Publish Instagram Reels",
                category=CapabilityCategory.MEDIA,
                status=CapabilityStatus.SUPPORTED,
                notes="Supported with media_type=REELS via Instagram Reels Publishing API",
            ),
            PlatformCapabilityModel(
                code="publish_stories",
                name="Instagram Stories Publishing",
                category=CapabilityCategory.PUBLISHING,
                status=CapabilityStatus.RESTRICTED,
                notes="Requires approved App Review for Instagram Stories Content Publishing",
            ),
            PlatformCapabilityModel(
                code="insights_analytics",
                name="Account & Media Insights",
                category=CapabilityCategory.ANALYTICS,
                status=CapabilityStatus.SUPPORTED,
                notes="Reads reach, impressions, profile views, and engagement metrics",
            ),
        ]

    def get_authorization_url(
        self,
        workspace_id: str,
        redirect_uri: str,
        state_token: str,
        code_verifier: Optional[str] = None,
    ) -> str:
        params = {
            "client_id": settings.META_APP_ID,
            "redirect_uri": redirect_uri,
            "state": state_token,
            "scope": ",".join(self.DEFAULT_SCOPES),
            "response_type": "code",
        }
        return f"{self.OAUTH_DIALOG_URL}?{urllib.parse.urlencode(params)}"

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
                short_token = body["access_token"]

                # Long-lived exchange
                long_params = {
                    "grant_type": "fb_exchange_token",
                    "client_id": settings.META_APP_ID,
                    "client_secret": settings.META_APP_SECRET,
                    "fb_exchange_token": short_token,
                }
                long_res = await client.get(f"{self.GRAPH_BASE}/oauth/access_token", params=long_params)
                long_body = long_res.json() if long_res.status_code == 200 else body

                return TokenBundle(
                    access_token=long_body.get("access_token", short_token),
                    expires_in=long_body.get("expires_in", 5184000),
                    scopes=self.DEFAULT_SCOPES,
                    raw_response=long_body,
                )
            except httpx.RequestError as e:
                raise PlatformServiceUnavailableException(self.platform_identifier, str(e))

    async def discover_channels(self, token: str) -> List[DiscoveredChannel]:
        """Discover linked Instagram Professional Accounts via authorized Facebook Pages."""
        params = {
            "fields": "id,name,instagram_business_account{id,username,name,profile_picture_url,followers_count}",
            "access_token": token,
        }
        channels: List[DiscoveredChannel] = []
        async with self.create_http_client() as client:
            try:
                res = await client.get(f"{self.GRAPH_BASE}/me/accounts", params=params)
                if res.status_code == 200:
                    data = res.json().get("data", [])
                    for page in data:
                        ig = page.get("instagram_business_account")
                        if ig and "id" in ig:
                            channels.append(
                                DiscoveredChannel(
                                    channel_id=ig["id"],
                                    name=f"@{ig.get('username', ig.get('name', 'Instagram'))}",
                                    category="Instagram Business/Creator",
                                    avatar_url=ig.get("profile_picture_url"),
                                    access_token=token,
                                    is_eligible=True,
                                )
                            )
                        else:
                            channels.append(
                                DiscoveredChannel(
                                    channel_id=f"page_no_ig_{page['id']}",
                                    name=f"{page.get('name')} (No Instagram Linked)",
                                    category="Unlinked Page",
                                    is_eligible=False,
                                    eligibility_reason="This Facebook Page has no linked Instagram Professional Account. Please link an Instagram Business/Creator account in Facebook Page Settings.",
                                )
                            )
                return channels
            except Exception:
                return []

    async def fetch_profile(
        self,
        token: str,
        account_id: Optional[str] = None,
    ) -> AccountProfile:
        if not account_id:
            # Attempt to discover first eligible Instagram account
            discovered = await self.discover_channels(token)
            eligible = [c for c in discovered if c.is_eligible]
            if not eligible:
                raise AccountNotEligibleException(
                    self.platform_identifier,
                    "No linked Instagram Professional account found. Please connect your Instagram Business or Creator account to a Facebook Page.",
                )
            account_id = eligible[0].channel_id

        params = {
            "fields": "id,username,name,profile_picture_url,followers_count,media_count",
            "access_token": token,
        }
        async with self.create_http_client() as client:
            try:
                res = await client.get(f"{self.GRAPH_BASE}/{account_id}", params=params)
                if res.status_code == 429:
                    raise PlatformRateLimitException(self.platform_identifier)
                if res.status_code != 200:
                    raise OAuthTokenExchangeException(self.platform_identifier, res.text)

                data = res.json()
                return AccountProfile(
                    platform_account_id=data["id"],
                    username=f"@{data.get('username', data.get('name', 'instagram_user'))}",
                    display_name=data.get("name") or data.get("username", "Instagram Account"),
                    account_type="business",
                    profile_image_url=data.get("profile_picture_url"),
                    follower_count=data.get("followers_count", 0),
                    metadata=data,
                )
            except httpx.RequestError as e:
                raise PlatformServiceUnavailableException(self.platform_identifier, str(e))

    async def validate_token(self, token: str) -> bool:
        params = {"fields": "id", "access_token": token}
        async with self.create_http_client() as client:
            try:
                res = await client.get(f"{self.GRAPH_BASE}/me", params=params)
                return res.status_code == 200
            except Exception:
                return False
