from typing import Any, Dict, List
from pydantic import BaseModel, Field


class AnalyticsOverviewResponse(BaseModel):
    workspace_id: str
    period: str = "last_7_days"
    total_posts: int = Field(..., example=56)
    total_engagement: int = Field(..., example=8700)
    total_reach: int = Field(..., example=34200)
    total_clicks: int = Field(..., example=1240)
    time_saved_hours: float = Field(..., example=16.5)
    upcoming_posts_count: int = Field(..., example=24)
    daily_performance: List[Dict[str, Any]] = Field(default_factory=list)


class PlatformMetricsItem(BaseModel):
    platform: str
    followers: int
    engagement_rate: float
    posts_count: int
    impressions: int


class PlatformAnalyticsResponse(BaseModel):
    workspace_id: str
    platforms: List[PlatformMetricsItem]

