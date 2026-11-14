from typing import Any, Dict, List, Optional
from pydantic import BaseModel, Field


class AnalyticsOverviewResponse(BaseModel):
    workspace_id: str
    period: str = "last_7_days"
    total_posts: int = 0
    total_engagement: int = 0
    total_reach: int = 0
    total_clicks: int = 0
    time_saved_hours: float = 0.0
    upcoming_posts_count: int = 0
    total_accounts: int = 0
    total_followers: int = 0
    published_posts_count: int = 0
    failed_posts_count: int = 0
    publishing_success_rate: float = 0.0
    total_impressions: int = 0
    daily_performance: List[Dict[str, Any]] = Field(default_factory=list)


class PlatformMetricsItem(BaseModel):
    platform: str
    followers: int = 0
    engagement_rate: float = 0.0
    posts_count: int = 0
    impressions: int = 0
    connected_accounts_count: Optional[int] = 0
    is_supported: bool = True


class PlatformAnalyticsResponse(BaseModel):
    workspace_id: str
    platforms: List[PlatformMetricsItem]


class AccountAnalyticsSnapshot(BaseModel):
    date: str
    followers: int
    impressions: int
    reach: int
    engagement_rate: float


class AccountAnalyticsResponse(BaseModel):
    account_id: str
    account_name: str
    platform: str
    followers_count: int
    last_sync_at: Optional[str] = None
    snapshots_count: int = 0
    historical_snapshots: List[AccountAnalyticsSnapshot] = Field(default_factory=list)


class PostTargetMetric(BaseModel):
    target_id: str
    platform: str
    account_name: str
    status: str
    external_post_id: Optional[str] = None
    impressions: int = 0
    reach: int = 0
    likes: int = 0
    comments: int = 0
    shares: int = 0
    clicks: int = 0


class PostAnalyticsResponse(BaseModel):
    post_id: str
    title: Optional[str] = None
    published_at: Optional[str] = None
    targets: List[PostTargetMetric] = Field(default_factory=list)


class AnalyticsSyncResponse(BaseModel):
    workspace_id: str
    synced_accounts: int
    status: str = "success"
    message: str = "Analytics synchronization completed successfully."
