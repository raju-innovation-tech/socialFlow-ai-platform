from sqlalchemy import Column, DateTime, ForeignKey, Integer, String, Text
from sqlalchemy.orm import relationship
from app.core.database import Base
from app.models.base import TimestampMixin, UUIDMixin


class ContentCategory(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "content_categories"

    workspace_id = Column(String(36), ForeignKey("workspaces.id", ondelete="CASCADE"), nullable=False, index=True)
    name = Column(String(100), nullable=False)
    color_hex = Column(String(7), default="#6C8CFF", nullable=False)
    description = Column(String(255), nullable=True)

    # Relationships
    posts = relationship("Post", back_populates="category")


class Post(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "posts"

    workspace_id = Column(String(36), ForeignKey("workspaces.id", ondelete="CASCADE"), nullable=False, index=True)
    category_id = Column(String(36), ForeignKey("content_categories.id", ondelete="SET NULL"), nullable=True)
    created_by_user_id = Column(String(36), ForeignKey("users.id", ondelete="SET NULL"), nullable=True)

    title = Column(String(255), nullable=True)
    content = Column(Text, nullable=False)
    content_type = Column(String(32), default="text", nullable=False)  # text, image, video, carousel, reel, poll
    status = Column(String(32), default="draft", index=True, nullable=False)  # draft, scheduled, publishing, published, failed, pending_approval

    scheduled_at = Column(DateTime(timezone=True), nullable=True, index=True)
    published_at = Column(DateTime(timezone=True), nullable=True)

    # Relationships
    workspace = relationship("Workspace", back_populates="posts")
    category = relationship("ContentCategory", back_populates="posts")
    variants = relationship("PostVariant", back_populates="post", cascade="all, delete-orphan")
    targets = relationship("PostTarget", back_populates="post", cascade="all, delete-orphan")
    media_items = relationship("PostMedia", back_populates="post", cascade="all, delete-orphan")
    campaign_links = relationship("CampaignPost", back_populates="post", cascade="all, delete-orphan")
    publishing_jobs = relationship("PublishingJob", back_populates="post", cascade="all, delete-orphan")
    post_metrics = relationship("PostMetric", back_populates="post", cascade="all, delete-orphan")
    approvals = relationship("PostApproval", back_populates="post", cascade="all, delete-orphan")


class PostVariant(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "post_variants"

    post_id = Column(String(36), ForeignKey("posts.id", ondelete="CASCADE"), nullable=False, index=True)
    platform = Column(String(32), nullable=False)  # linkedin, twitter, instagram, etc.
    customized_content = Column(Text, nullable=False)

    # Relationships
    post = relationship("Post", back_populates="variants")


class PostTarget(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "post_targets"

    post_id = Column(String(36), ForeignKey("posts.id", ondelete="CASCADE"), nullable=False, index=True)
    social_account_id = Column(String(36), ForeignKey("social_accounts.id", ondelete="CASCADE"), nullable=False, index=True)
    status = Column(String(32), default="pending", nullable=False)  # pending, publishing, published, failed
    external_post_id = Column(String(255), nullable=True)
    published_at = Column(DateTime(timezone=True), nullable=True)
    error_message = Column(Text, nullable=True)

    # Relationships
    post = relationship("Post", back_populates="targets")
    account = relationship("SocialAccount", back_populates="targets")


class PostMedia(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "post_media"

    post_id = Column(String(36), ForeignKey("posts.id", ondelete="CASCADE"), nullable=False, index=True)
    media_asset_id = Column(String(36), ForeignKey("media_assets.id", ondelete="CASCADE"), nullable=False, index=True)
    display_order = Column(Integer, default=0, nullable=False)

    # Relationships
    post = relationship("Post", back_populates="media_items")
    media_asset = relationship("MediaAsset", back_populates="post_links")

