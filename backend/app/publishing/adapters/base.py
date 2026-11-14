from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from typing import Any, Dict, List, Optional
import httpx

from app.models.media import MediaAsset
from app.models.social_account import SocialAccount


@dataclass
class PublishingResult:
    """Standardized response from platform publishing adapters."""
    success: bool
    external_post_id: Optional[str] = None
    external_post_url: Optional[str] = None
    error_code: Optional[str] = None
    error_message: Optional[str] = None
    is_retryable: bool = False
    raw_response: Dict[str, Any] = field(default_factory=dict)


class BasePublishingAdapter(ABC):
    """Abstract base class for all 7 platform publishing adapters."""

    @property
    @abstractmethod
    def platform_identifier(self) -> str:
        """Identifier matching social account platform (e.g. 'linkedin', 'facebook', etc.)."""
        pass

    @abstractmethod
    def validate_content(
        self,
        text: str,
        media_items: Optional[List[MediaAsset]] = None,
        extra_params: Optional[Dict[str, Any]] = None,
    ) -> List[str]:
        """Validate content against platform rules before publishing. Returns list of error strings."""
        pass

    @abstractmethod
    async def publish(
        self,
        account: SocialAccount,
        decrypted_token: str,
        text: str,
        media_items: Optional[List[MediaAsset]] = None,
        extra_params: Optional[Dict[str, Any]] = None,
    ) -> PublishingResult:
        """Publish content to the official platform API."""
        pass

    def create_http_client(self, timeout: float = 30.0) -> httpx.AsyncClient:
        """Create standard HTTP client with appropriate timeout."""
        return httpx.AsyncClient(timeout=timeout)

