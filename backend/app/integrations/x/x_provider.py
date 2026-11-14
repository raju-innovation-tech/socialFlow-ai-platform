import base64
import hashlib
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


class XProvider(BasePlatformProvider):
    AUTH_URL = "https://twitter.com/i/oauth2/authorize"
    TOKEN_URL = "https://api.twitter.com/2/oauth2/token"
    REVOKE_URL = "https://api.twitter.com/2/oauth2/revoke"
    ME_URL = "https://api.twitter.com/2/users/me"

    DEFAULT_SCOPES = [
        "tweet.read",
        "tweet.write",
        "users.read",
        "offline.access",
    ]

    @property
    def platform_identifier(self) -> str:
        return "x"

    @property
    def platform_name(self) -> str:
        return "X (Formerly Twitter)"

    def get_capabilities(self) -> List[PlatformCapabilityModel]:
        return [
            PlatformCapabilityModel(
                code="oauth_pkce",
                name="OAuth 2.0 with PKCE",
                category=CapabilityCategory.AUTHENTICATION,
                status=CapabilityStatus.SUPPORTED,
                notes="X API v2 standard authorization with SHA-256 code challenge",
                doc_url="https://developer.x.com/en/docs/authentication/oauth-2-0/authorization-code-with-pkce",
            ),
            PlatformCapabilityModel(
                code="publish_tweet",
                name="Publish Single Tweet / Post",
                category=CapabilityCategory.PUBLISHING,
                status=CapabilityStatus.SUPPORTED,
                notes="Supported via POST /2/tweets endpoint",
            ),
            PlatformCapabilityModel(
                code="publish_thread",
                name="Publish Multi-Tweet Thread",
                category=CapabilityCategory.PUBLISHING,
                status=CapabilityStatus.SUPPORTED,
                notes="Sequential posting with in_reply_to_tweet_id chaining",
            ),
            PlatformCapabilityModel(
                code="media_upload",
                name="Image & Video Attachments",
                category=CapabilityCategory.MEDIA,
                status=CapabilityStatus.SUPPORTED,
                notes="Supports up to 4 images or 1 video up to 512MB",
            ),
            PlatformCapabilityModel(
                code="poll_tweets",
                name="Publish Interactive Polls",
                category=CapabilityCategory.PUBLISHING,
                status=CapabilityStatus.SUPPORTED,
                notes="Supported with 2 to 4 options and customizable duration",
            ),
            PlatformCapabilityModel(
                code="free_tier_restrictions",
                name="Free Access Tier Limitations",
                category=CapabilityCategory.AUTHENTICATION,
                status=CapabilityStatus.RESTRICTED,
                notes="Free tier is limited to 1,500 post writes per month. Read analytics requires Basic ($100/mo) tier.",
                doc_url="https://developer.x.com/en/docs/twitter-api/getting-started/about-twitter-api",
            ),
            PlatformCapabilityModel(
                code="direct_messages",
                name="Direct Message Automation",
                category=CapabilityCategory.COMMUNITY,
                status=CapabilityStatus.RESTRICTED,
                notes="Requires explicit dm.read / dm.write permissions and approved elevated access",
            ),
        ]

    def get_authorization_url(
        self,
        workspace_id: str,
        redirect_uri: str,
        state_token: str,
        code_verifier: Optional[str] = None,
    ) -> str:
        # Calculate PKCE code_challenge (S256)
        if not code_verifier:
            code_verifier = "default_socialflow_pkce_verifier_string_min_43_chars"
        code_challenge = base64.urlsafe_b64encode(
            hashlib.sha256(code_verifier.encode("ascii")).digest()
        ).decode("ascii").rstrip("=")

        params = {
            "response_type": "code",
            "client_id": settings.X_CLIENT_ID,
            "redirect_uri": redirect_uri,
            "scope": " ".join(self.DEFAULT_SCOPES),
            "state": state_token,
            "code_challenge": code_challenge,
            "code_challenge_method": "S256",
        }
        return f"{self.AUTH_URL}?{urllib.parse.urlencode(params)}"

    async def exchange_code_for_token(
        self,
        code: str,
        redirect_uri: str,
        code_verifier: Optional[str] = None,
    ) -> TokenBundle:
        data = {
            "code": code,
            "grant_type": "authorization_code",
            "client_id": settings.X_CLIENT_ID,
            "redirect_uri": redirect_uri,
            "code_verifier": code_verifier or "",
        }
        # X API v2 accepts Basic auth or client_id in body for confidential clients
        auth = None
        if settings.X_CLIENT_SECRET:
            auth = (settings.X_CLIENT_ID, settings.X_CLIENT_SECRET)

        headers = {"Content-Type": "application/x-www-form-urlencoded"}

        async with self.create_http_client() as client:
            try:
                res = await client.post(self.TOKEN_URL, data=data, auth=auth, headers=headers)
                if res.status_code == 429:
                    raise PlatformRateLimitException(self.platform_identifier)
                if res.status_code != 200:
                    raise OAuthTokenExchangeException(self.platform_identifier, res.text)

                body = res.json()
                return TokenBundle(
                    access_token=body["access_token"],
                    refresh_token=body.get("refresh_token"),
                    expires_in=body.get("expires_in", 7200),  # Typically 2 hours
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
        headers = {"Authorization": f"Bearer {token}"}
        params = {"user.fields": "id,name,username,profile_image_url,public_metrics"}

        async with self.create_http_client() as client:
            try:
                res = await client.get(self.ME_URL, headers=headers, params=params)
                if res.status_code == 429:
                    raise PlatformRateLimitException(self.platform_identifier)
                if res.status_code != 200:
                    raise OAuthTokenExchangeException(self.platform_identifier, res.text)

                data = res.json().get("data", {})
                metrics = data.get("public_metrics", {})
                followers = metrics.get("followers_count", 0)

                return AccountProfile(
                    platform_account_id=data["id"],
                    username=f"@{data['username']}",
                    display_name=data["name"],
                    account_type="profile",
                    profile_image_url=data.get("profile_image_url"),
                    follower_count=followers,
                    metadata=data,
                )
            except httpx.RequestError as e:
                raise PlatformServiceUnavailableException(self.platform_identifier, str(e))

    async def refresh_access_token(self, refresh_token: str) -> Optional[TokenBundle]:
        data = {
            "refresh_token": refresh_token,
            "grant_type": "refresh_token",
            "client_id": settings.X_CLIENT_ID,
        }
        auth = (settings.X_CLIENT_ID, settings.X_CLIENT_SECRET) if settings.X_CLIENT_SECRET else None
        async with self.create_http_client() as client:
            try:
                res = await client.post(self.TOKEN_URL, data=data, auth=auth)
                if res.status_code == 200:
                    body = res.json()
                    return TokenBundle(
                        access_token=body["access_token"],
                        refresh_token=body.get("refresh_token", refresh_token),
                        expires_in=body.get("expires_in", 7200),
                    )
                return None
            except Exception:
                return None

    async def validate_token(self, token: str) -> bool:
        headers = {"Authorization": f"Bearer {token}"}
        async with self.create_http_client() as client:
            try:
                res = await client.get(self.ME_URL, headers=headers)
                return res.status_code == 200
            except Exception:
                return False
