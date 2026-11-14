from abc import ABC, abstractmethod
from typing import Any, Dict, List, Optional
import httpx

from app.integrations.base.capability_models import (
    AccountProfile,
    DiscoveredChannel,
    PlatformCapabilityModel,
    TokenBundle,
)


class BasePlatformProvider(ABC):
    """Abstract base class that all 7 social platform integrations must implement."""

    @property
    @abstractmethod
    def platform_identifier(self) -> str:
        """Unique identifier (e.g. 'linkedin', 'facebook', 'instagram', 'youtube', 'x', 'whatsapp', 'telegram')."""
        pass

    @property
    @abstractmethod
    def platform_name(self) -> str:
        """Display name (e.g. 'LinkedIn', 'Facebook Pages')."""
        pass

    @abstractmethod
    def get_capabilities(self) -> List[PlatformCapabilityModel]:
        """List official capabilities and their exact support status on this platform."""
        pass

    @abstractmethod
    def get_authorization_url(
        self,
        workspace_id: str,
        redirect_uri: str,
        state_token: str,
        code_verifier: Optional[str] = None,
    ) -> str:
        """Generate official OAuth 2.0 or authorization onboarding URL."""
        pass

    @abstractmethod
    async def exchange_code_for_token(
        self,
        code: str,
        redirect_uri: str,
        code_verifier: Optional[str] = None,
    ) -> TokenBundle:
        """Exchange authorization code for access and refresh tokens."""
        pass

    @abstractmethod
    async def fetch_profile(
        self,
        token: str,
        account_id: Optional[str] = None,
    ) -> AccountProfile:
        """Fetch verified profile details of the authorized identity."""
        pass

    async def discover_channels(self, token: str) -> List[DiscoveredChannel]:
        """Discover manageable sub-entities like Facebook Pages, Instagram Accounts, or YouTube Channels.
        Default implementation returns empty list for profile-only platforms.
        """
        return []

    @abstractmethod
    async def validate_token(self, token: str) -> bool:
        """Verify token validity against official platform API."""
        pass

    async def refresh_access_token(self, refresh_token: str) -> Optional[TokenBundle]:
        """Refresh expired access token if officially supported by platform."""
        return None

    async def revoke_access(self, token: str) -> bool:
        """Revoke token or disconnect integration on the platform side."""
        return True

    def create_http_client(self, timeout: float = 15.0) -> httpx.AsyncClient:
        """Helper to create standardized HTTP client with timeout."""
        return httpx.AsyncClient(timeout=timeout)

