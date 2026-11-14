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


class YouTubeProvider(BasePlatformProvider):
    AUTH_URL = "https://accounts.google.com/o/oauth2/v2/auth"
    TOKEN_URL = "https://oauth2.googleapis.com/token"
    REVOKE_URL = "https://oauth2.googleapis.com/revoke"
    CHANNELS_URL = "https://www.googleapis.com/youtube/v3/channels"

    DEFAULT_SCOPES = [
        "https://www.googleapis.com/auth/youtube.readonly",
        "https://www.googleapis.com/auth/youtube.upload",
        "https://www.googleapis.com/auth/userinfo.profile",
    ]

    @property
    def platform_identifier(self) -> str:
        return "youtube"

    @property
    def platform_name(self) -> str:
        return "YouTube"

    def get_capabilities(self) -> List[PlatformCapabilityModel]:
        return [
            PlatformCapabilityModel(
                code="channel_selection",
                name="Multi-Channel Discovery & Selection",
                category=CapabilityCategory.AUTHENTICATION,
                status=CapabilityStatus.SUPPORTED,
                notes="Google OAuth with channels?mine=true allows choosing specific channel",
                doc_url="https://developers.google.com/youtube/v3/docs/channels/list",
            ),
            PlatformCapabilityModel(
                code="upload_video",
                name="Upload Long-Form Video",
                category=CapabilityCategory.MEDIA,
                status=CapabilityStatus.SUPPORTED,
                notes="Supported via YouTube Resumable Upload API (1,600 quota units per upload)",
            ),
            PlatformCapabilityModel(
                code="upload_shorts",
                name="Upload YouTube Shorts",
                category=CapabilityCategory.MEDIA,
                status=CapabilityStatus.SUPPORTED,
                notes="Vertical 9:16 videos <= 60 seconds with #Shorts tag in title/description",
            ),
            PlatformCapabilityModel(
                code="publish_text_community",
                name="Community Tab Text Posts",
                category=CapabilityCategory.PUBLISHING,
                status=CapabilityStatus.UNAVAILABLE,
                notes="Google YouTube Data API v3 does not expose endpoints to create Community tab text posts",
            ),
            PlatformCapabilityModel(
                code="channel_analytics",
                name="Channel & Video Metrics",
                category=CapabilityCategory.ANALYTICS,
                status=CapabilityStatus.SUPPORTED,
                notes="Reads viewCount, subscriberCount, commentCount from statistics part",
            ),
            PlatformCapabilityModel(
                code="quota_management",
                name="Daily Quota Awareness",
                category=CapabilityCategory.AUTHENTICATION,
                status=CapabilityStatus.RESTRICTED,
                notes="Standard Google Cloud default quota is 10,000 units/day. Video upload costs 1,600 units.",
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
            "client_id": settings.GOOGLE_CLIENT_ID,
            "redirect_uri": redirect_uri,
            "response_type": "code",
            "scope": " ".join(self.DEFAULT_SCOPES),
            "state": state_token,
            "access_type": "offline",  # Required for refresh_token
            "prompt": "consent",       # Required to ensure refresh_token returned
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
            "client_id": settings.GOOGLE_CLIENT_ID,
            "client_secret": settings.GOOGLE_CLIENT_SECRET,
            "redirect_uri": redirect_uri,
            "grant_type": "authorization_code",
        }
        async with self.create_http_client() as client:
            try:
                res = await client.post(self.TOKEN_URL, data=data)
                if res.status_code == 429:
                    raise PlatformRateLimitException(self.platform_identifier)
                if res.status_code != 200:
                    raise OAuthTokenExchangeException(self.platform_identifier, res.text)

                body = res.json()
                return TokenBundle(
                    access_token=body["access_token"],
                    refresh_token=body.get("refresh_token"),
                    expires_in=body.get("expires_in", 3600),
                    scopes=body.get("scope", "").split(),
                    raw_response=body,
                )
            except httpx.RequestError as e:
                raise PlatformServiceUnavailableException(self.platform_identifier, str(e))

    async def discover_channels(self, token: str) -> List[DiscoveredChannel]:
        """Fetch all YouTube channels associated with authorized Google account."""
        headers = {"Authorization": f"Bearer {token}"}
        params = {"part": "snippet,contentDetails,statistics", "mine": "true"}
        channels: List[DiscoveredChannel] = []

        async with self.create_http_client() as client:
            try:
                res = await client.get(self.CHANNELS_URL, headers=headers, params=params)
                if res.status_code == 200:
                    items = res.json().get("items", [])
                    for item in items:
                        snippet = item.get("snippet", {})
                        thumbs = snippet.get("thumbnails", {})
                        thumb_url = thumbs.get("default", {}).get("url")
                        channels.append(
                            DiscoveredChannel(
                                channel_id=item["id"],
                                name=snippet.get("title", "YouTube Channel"),
                                category="YouTube Channel",
                                avatar_url=thumb_url,
                                access_token=token,
                                is_eligible=True,
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
        headers = {"Authorization": f"Bearer {token}"}
        params = {"part": "snippet,statistics", "mine": "true"} if not account_id else {
            "part": "snippet,statistics", "id": account_id
        }

        async with self.create_http_client() as client:
            try:
                res = await client.get(self.CHANNELS_URL, headers=headers, params=params)
                if res.status_code == 429:
                    raise PlatformRateLimitException(self.platform_identifier)
                if res.status_code != 200:
                    raise OAuthTokenExchangeException(self.platform_identifier, res.text)

                items = res.json().get("items", [])
                if not items:
                    raise AccountNotEligibleException(
                        self.platform_identifier,
                        "No YouTube channel was found on this Google account. Please create a channel on YouTube first.",
                    )

                channel = items[0]
                snippet = channel.get("snippet", {})
                stats = channel.get("statistics", {})
                thumb_url = snippet.get("thumbnails", {}).get("default", {}).get("url")
                sub_count = int(stats.get("subscriberCount", 0))

                return AccountProfile(
                    platform_account_id=channel["id"],
                    username=snippet.get("customUrl") or snippet.get("title", "youtube_channel"),
                    display_name=snippet.get("title", "YouTube Channel"),
                    account_type="channel",
                    profile_image_url=thumb_url,
                    follower_count=sub_count,
                    metadata=channel,
                )
            except httpx.RequestError as e:
                raise PlatformServiceUnavailableException(self.platform_identifier, str(e))

    async def refresh_access_token(self, refresh_token: str) -> Optional[TokenBundle]:
        data = {
            "client_id": settings.GOOGLE_CLIENT_ID,
            "client_secret": settings.GOOGLE_CLIENT_SECRET,
            "refresh_token": refresh_token,
            "grant_type": "refresh_token",
        }
        async with self.create_http_client() as client:
            try:
                res = await client.post(self.TOKEN_URL, data=data)
                if res.status_code == 200:
                    body = res.json()
                    return TokenBundle(
                        access_token=body["access_token"],
                        refresh_token=refresh_token,
                        expires_in=body.get("expires_in", 3600),
                    )
                return None
            except Exception:
                return None

    async def validate_token(self, token: str) -> bool:
        headers = {"Authorization": f"Bearer {token}"}
        params = {"part": "id", "mine": "true"}
        async with self.create_http_client() as client:
            try:
                res = await client.get(self.CHANNELS_URL, headers=headers, params=params)
                return res.status_code == 200
            except Exception:
                return False

