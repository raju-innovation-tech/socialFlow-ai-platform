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
    OAuthTokenExchangeException,
    PlatformRateLimitException,
    PlatformServiceUnavailableException,
)


class FacebookProvider(BasePlatformProvider):
    GRAPH_API_VERSION = "v20.0"
    GRAPH_BASE = "https://graph.facebook.com/v20.0"
    OAUTH_DIALOG_URL = "https://www.facebook.com/v20.0/dialog/oauth"

    DEFAULT_SCOPES = [
        "public_profile",
        "email",
        "pages_show_list",
        "pages_read_engagement",
        "pages_manage_posts",
    ]

    @property
    def platform_identifier(self) -> str:
        return "facebook"

    @property
    def platform_name(self) -> str:
        return "Facebook Pages"

    def get_capabilities(self) -> List[PlatformCapabilityModel]:
        return [
            PlatformCapabilityModel(
                code="connect_pages",
                name="Connect Facebook Pages",
                category=CapabilityCategory.AUTHENTICATION,
                status=CapabilityStatus.SUPPORTED,
                notes="Connects managed business Facebook Pages via pages_show_list",
                doc_url="https://developers.facebook.com/docs/pages-api",
            ),
            PlatformCapabilityModel(
                code="personal_profile_posting",
                name="Personal Profile Automated Posting",
                category=CapabilityCategory.PUBLISHING,
                status=CapabilityStatus.UNAVAILABLE,
                notes="Meta Graph API strictly prohibits automated publishing to personal user timelines",
            ),
            PlatformCapabilityModel(
                code="publish_text",
                name="Publish Feed Post",
                category=CapabilityCategory.PUBLISHING,
                status=CapabilityStatus.SUPPORTED,
                notes="Publishes text updates to Page feed with pages_manage_posts",
            ),
            PlatformCapabilityModel(
                code="publish_image",
                name="Publish Single & Multi-Photos",
                category=CapabilityCategory.MEDIA,
                status=CapabilityStatus.SUPPORTED,
                notes="Direct photo upload via Page /photos endpoint",
            ),
            PlatformCapabilityModel(
                code="publish_video",
                name="Publish Native Video & Reels",
                category=CapabilityCategory.MEDIA,
                status=CapabilityStatus.SUPPORTED,
                notes="Supported via Page /videos and /video_reels endpoints",
            ),
            PlatformCapabilityModel(
                code="page_analytics",
                name="Page & Post Insights",
                category=CapabilityCategory.ANALYTICS,
                status=CapabilityStatus.SUPPORTED,
                notes="Reads impressions, engagement, and reach via /insights",
            ),
            PlatformCapabilityModel(
                code="webhooks",
                name="Page Webhooks (Comments, Leads, Mentions)",
                category=CapabilityCategory.WEBHOOKS,
                status=CapabilityStatus.SUPPORTED,
                notes="Meta Webhook subscription with HMAC SHA-256 signature verification",
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
                # 1. Exchange code for short-lived user token
                res = await client.get(f"{self.GRAPH_BASE}/oauth/access_token", params=params)
                if res.status_code == 429:
                    raise PlatformRateLimitException(self.platform_identifier)
                if res.status_code != 200:
                    raise OAuthTokenExchangeException(self.platform_identifier, res.text)
                body = res.json()
                short_token = body["access_token"]

                # 2. Exchange short-lived token for long-lived 60-day token
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
                    expires_in=long_body.get("expires_in", 5184000),  # 60 days
                    scopes=self.DEFAULT_SCOPES,
                    raw_response=long_body,
                )
            except httpx.RequestError as e:
                raise PlatformServiceUnavailableException(self.platform_identifier, str(e))

    async def fetch_profile(
        self,
        token: str,
        account_id: Optional[str] = None,
    ) -> AccountProfile:
        target = account_id if account_id else "me"
        params = {
            "fields": "id,name,picture.width(200).height(200){url},fan_count",
            "access_token": token,
        }
        async with self.create_http_client() as client:
            try:
                res = await client.get(f"{self.GRAPH_BASE}/{target}", params=params)
                if res.status_code == 429:
                    raise PlatformRateLimitException(self.platform_identifier)
                if res.status_code != 200:
                    raise OAuthTokenExchangeException(self.platform_identifier, res.text)

                data = res.json()
                pic_data = data.get("picture", {}).get("data", {})
                return AccountProfile(
                    platform_account_id=data["id"],
                    username=data.get("name", "Facebook Page"),
                    display_name=data["name"],
                    account_type="page",
                    profile_image_url=pic_data.get("url"),
                    follower_count=data.get("fan_count", 0),
                    metadata=data,
                )
            except httpx.RequestError as e:
                raise PlatformServiceUnavailableException(self.platform_identifier, str(e))

    async def discover_channels(self, token: str) -> List[DiscoveredChannel]:
        """Fetch accessible Facebook Pages with their respective Page Access Tokens."""
        params = {
            "fields": "id,name,category,access_token,picture{url},tasks",
            "access_token": token,
        }
        channels: List[DiscoveredChannel] = []
        async with self.create_http_client() as client:
            try:
                res = await client.get(f"{self.GRAPH_BASE}/me/accounts", params=params)
                if res.status_code == 200:
                    data = res.json().get("data", [])
                    for item in data:
                        pic_url = item.get("picture", {}).get("data", {}).get("url")
                        channels.append(
                            DiscoveredChannel(
                                channel_id=item["id"],
                                name=item["name"],
                                category=item.get("category", "Facebook Page"),
                                avatar_url=pic_url,
                                access_token=item.get("access_token"),
                                is_eligible=True,
                            )
                        )
                return channels
            except Exception:
                return []

    async def validate_token(self, token: str) -> bool:
        params = {"fields": "id", "access_token": token}
        async with self.create_http_client() as client:
            try:
                res = await client.get(f"{self.GRAPH_BASE}/me", params=params)
                return res.status_code == 200
            except Exception:
                return False

