from sqlalchemy import Column, Date, DateTime, ForeignKey, Integer, Numeric, String, Text
from sqlalchemy.orm import relationship
from app.core.database import Base
from app.models.base import TimestampMixin, UUIDMixin


class AnalyticsSnapshot(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "analytics_snapshots"

    account_id = Column(String(36), ForeignKey("social_accounts.id", ondelete="CASCADE"), nullable=False, index=True)
    snapshot_date = Column(Date, nullable=False, index=True)
    followers_count = Column(Integer, default=0, nullable=False)
    impressions_count = Column(Integer, default=0, nullable=False)
    reach_count = Column(Integer, default=0, nullable=False)
    engagement_rate = Column(Numeric(5, 2), default=0.00, nullable=False)
    raw_metrics_json = Column(Text, nullable=True)

    # Relationships
    account = relationship("SocialAccount", back_populates="analytics_snapshots")


class PlatformMetric(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "platform_metrics"

    platform = Column(String(32), nullable=False, index=True)
    metric_name = Column(String(64), nullable=False)  # views, engagement, clicks, reach
    metric_value = Column(Numeric(14, 2), nullable=False)
    collection_date = Column(Date, nullable=False, index=True)
    dimension_tags = Column(String(255), nullable=True)  # e.g., "reels,organic"


class PostMetric(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "post_metrics"

    post_id = Column(String(36), ForeignKey("posts.id", ondelete="CASCADE"), nullable=False, index=True)
    social_account_id = Column(String(36), ForeignKey("social_accounts.id", ondelete="CASCADE"), nullable=False, index=True)
    recorded_at = Column(DateTime(timezone=True), nullable=False, index=True)

    impressions = Column(Integer, default=0, nullable=False)
    reach = Column(Integer, default=0, nullable=False)
    likes = Column(Integer, default=0, nullable=False)
    comments = Column(Integer, default=0, nullable=False)
    shares = Column(Integer, default=0, nullable=False)
    clicks = Column(Integer, default=0, nullable=False)

    # Relationships
    post = relationship("Post", back_populates="post_metrics")

