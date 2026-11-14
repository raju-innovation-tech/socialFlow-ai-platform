from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional
import httpx

from app.models.social_account import SocialAccount


@dataclass
class AccountMetricsData:
    """Normalized metrics snapshot for a social account."""
    platform: str
    account_id: str
    followers_count: int
    impressions_count: int = 0
    reach_count: int = 0
    engagement_rate: float = 0.0
    metrics: Dict[str, Any] = field(default_factory=dict)
    collection_timestamp: datetime = field(default_factory=lambda: datetime.now(timezone.utc))
    is_available: bool = True
    unsupported_metrics: List[str] = field(default_factory=list)


@dataclass
class PostMetricsData:
    """Normalized performance metrics for an individual published post."""
    post_id: str
    external_post_id: str
    impressions: int = 0
    reach: int = 0
    likes: int = 0
    comments: int = 0
    shares: int = 0
    clicks: int = 0
    raw_metrics: Dict[str, Any] = field(default_factory=dict)
    collection_timestamp: datetime = field(default_factory=lambda: datetime.now(timezone.utc))


class BaseAnalyticsProvider(ABC):
    """Abstract interface implemented by all 7 platform analytics providers."""

    @property
    @abstractmethod
    def platform_identifier(self) -> str:
        pass

    @abstractmethod
    async def fetch_account_analytics(
        self,
        account: SocialAccount,
        decrypted_token: str,
        start_date: Optional[datetime] = None,
        end_date: Optional[datetime] = None,
    ) -> AccountMetricsData:
        """Fetch account-level statistics (followers, reach, engagement) from official platform API."""
        pass

    @abstractmethod
    async def fetch_post_analytics(
        self,
        account: SocialAccount,
        decrypted_token: str,
        external_post_id: str,
    ) -> PostMetricsData:
        """Fetch performance metrics for an individual published post."""
        pass

    def create_http_client(self, timeout: float = 15.0) -> httpx.AsyncClient:
        return httpx.AsyncClient(timeout=timeout)

