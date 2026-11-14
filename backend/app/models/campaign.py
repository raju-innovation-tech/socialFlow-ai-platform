from sqlalchemy import Column, DateTime, ForeignKey, Numeric, String, Text, UniqueConstraint
from sqlalchemy.orm import relationship
from app.core.database import Base
from app.models.base import TimestampMixin, UUIDMixin


class Campaign(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "campaigns"

    workspace_id = Column(String(36), ForeignKey("workspaces.id", ondelete="CASCADE"), nullable=False, index=True)
    name = Column(String(255), nullable=False)
    description = Column(Text, nullable=True)
    status = Column(String(32), default="active", nullable=False)  # draft, active, completed, paused
    start_date = Column(DateTime(timezone=True), nullable=True)
    end_date = Column(DateTime(timezone=True), nullable=True)
    budget_amount = Column(Numeric(12, 2), nullable=True)
    budget_currency = Column(String(3), default="USD", nullable=False)

    # Relationships
    workspace = relationship("Workspace", back_populates="campaigns")
    posts = relationship("CampaignPost", back_populates="campaign", cascade="all, delete-orphan")


class CampaignPost(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "campaign_posts"
    __table_args__ = (
        UniqueConstraint("campaign_id", "post_id", name="uq_campaign_post"),
    )

    campaign_id = Column(String(36), ForeignKey("campaigns.id", ondelete="CASCADE"), nullable=False, index=True)
    post_id = Column(String(36), ForeignKey("posts.id", ondelete="CASCADE"), nullable=False, index=True)

    # Relationships
    campaign = relationship("Campaign", back_populates="posts")
    post = relationship("Post", back_populates="campaign_links")

