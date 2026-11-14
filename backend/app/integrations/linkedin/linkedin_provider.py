import urllib.parse
from typing import Any, Dict, List, Optional
import httpx

from app.core.config import settings
from app.core.logging import logger
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


class LinkedInProvider(BasePlatformProvider):
    AUTH_URL = "https://www.linkedin.com/oauth/v2/authorization"
    TOKEN_URL = "https://www.linkedin.com/oauth/v2/accessToken"
    USERINFO_URL = "https://api.linkedin.com/v2/userinfo"

    DEFAULT_SCOPES = ["openid", "profile", "email", "w_member_social"]

    @property
    def platform_identifier(self) -> str:
        return "linkedin"

    @property
    def platform_name(self) -> str:
        return "LinkedIn"

    def get_capabilities(self) -> List[PlatformCapabilityModel]:
        return [
            PlatformCapabilityModel(
                code="connect_profile",
                name="Connect Personal Profile",
                category=CapabilityCategory.AUTHENTICATION,
                status=CapabilityStatus.SUPPORTED,
                notes="OAuth 2.0 OpenID Connect authorization",
                doc_url="https://learn.microsoft.com/en-us/linkedin/consumer/integrations/self-serve/sign-in-with-linkedin-v2",
            ),
            PlatformCapabilityModel(
                code="publish_text",
                name="Publish Text Update",
                category=CapabilityCategory.PUBLISHING,
                status=CapabilityStatus.SUPPORTED,
                notes="Posts to authorized member personal feed with w_member_social scope",
            ),
            PlatformCapabilityModel(
                code="publish_image",
                name="Publish Image Post",
                category=CapabilityCategory.MEDIA,
                status=CapabilityStatus.SUPPORTED,
                notes="Supported via LinkedIn Images API asset registration",
            ),
            PlatformCapabilityModel(
                code="publish_carousel",
                name="Publish Document / PDF Carousel",
                category=CapabilityCategory.MEDIA,
                status=CapabilityStatus.SUPPORTED,
                notes="Supported via vectorAsset document registration",
            ),
            PlatformCapabilityModel(
                code="publish_video",
                name="Publish Video",
                category=CapabilityCategory.MEDIA,
                status=CapabilityStatus.SUPPORTED,
                notes="Supported via LinkedIn Video Upload API",
            ),
            PlatformCapabilityModel(
                code="organization_posting",
                name="Company Page Publishing",
                category=CapabilityCategory.PUBLISHING,
                status=CapabilityStatus.REQUIRES_PERMISSION,
                notes="Requires approved w_organization_social scope via LinkedIn Community Management API",
                doc_url="https://learn.microsoft.com/en-us/linkedin/marketing/community-management/community-management-overview",
            ),
            PlatformCapabilityModel(
                code="reels",
                name="Reels / Short Form Video",
                category=CapabilityCategory.PUBLISHING,
                status=CapabilityStatus.UNAVAILABLE,
                notes="LinkedIn platform does not support Instagram-style Reels",
            ),
            PlatformCapabilityModel(
                code="webhooks",
                name="Real-time Webhook Events",
                category=CapabilityCategory.WEBHOOKS,
                status=CapabilityStatus.REQUIRES_PERMISSION,
                notes="Restricted to approved Enterprise Developer partners",
            ),
        ]

    def get_authorization_url(
        self,
        workspace_id: str,
        redirect_uri: str,
        state_token: str,
        code_verifier: Optional[str] = None,
    ) -> str:
        client_id = settings.LINKEDIN_CLIENT_ID
        params = {
            "response_type": "code",
            "client_id": client_id,
            "redirect_uri": redirect_uri,
            "state": state_token,
            "scope": " ".join(self.DEFAULT_SCOPES),
        }
        return f"{self.AUTH_URL}?{urllib.parse.urlencode(params)}"

    async def exchange_code_for_token(
        self,
        code: str,
        redirect_uri: str,
        code_verifier: Optional[str] = None,
    ) -> TokenBundle:
        data = {
            "grant_type": "authorization_code",
            "code": code,
            "client_id": settings.LINKEDIN_CLIENT_ID,
            "client_secret": settings.LINKEDIN_CLIENT_SECRET,
            "redirect_uri": redirect_uri,
        }
        headers = {"Content-Type": "application/x-www-form-urlencoded"}

        async with self.create_http_client() as client:
            try:
                res = await client.post(self.TOKEN_URL, data=data, headers=headers)
                if res.status_code == 429:
                    raise PlatformRateLimitException(self.platform_identifier)
                if res.status_code != 200:
                    err_msg = res.text
                    try:
                        err_msg = res.json().get("error_description", res.text)
                    except Exception:
                        pass
                    raise OAuthTokenExchangeException(self.platform_identifier, err_msg)

                body = res.json()
                return TokenBundle(
                    access_token=body["access_token"],
                    refresh_token=body.get("refresh_token"),
                    expires_in=body.get("expires_in", 5184000),  # Typically 60 days
                    scopes=body.get("scope", "").split(),
                    raw_response=body,
                )
            except httpx.RequestError as e:
                raise PlatformServiceUnavailableException(self.platform_identifier, str(e))

    async def fetch_profile(
        self,
        token: str,
        account_id: Optional[str] = None,
    ) -> AccountProfile:
        headers = {
            "Authorization": f"Bearer {token}",
            "Accept": "application/json",
        }
        async with self.create_http_client() as client:
            try:
                res = await client.get(self.USERINFO_URL, headers=headers)
                if res.status_code == 429:
                    raise PlatformRateLimitException(self.platform_identifier)
                if res.status_code != 200:
                    raise OAuthTokenExchangeException(self.platform_identifier, f"Userinfo returned {res.status_code}: {res.text}")

                data = res.json()
                sub_id = data.get("sub", "")
                name = data.get("name", "LinkedIn Member")
                email = data.get("email")
                picture = data.get("picture")

                return AccountProfile(
                    platform_account_id=sub_id,
                    username=email or sub_id,
                    display_name=name,
                    account_type="profile",
                    profile_image_url=picture,
                    follower_count=0,
                    email=email,
                    metadata=data,
                )
            except httpx.RequestError as e:
                raise PlatformServiceUnavailableException(self.platform_identifier, str(e))

    async def validate_token(self, token: str) -> bool:
        headers = {"Authorization": f"Bearer {token}"}
        async with self.create_http_client() as client:
            try:
                res = await client.get(self.USERINFO_URL, headers=headers)
                return res.status_code == 200
            except Exception:
                return False

