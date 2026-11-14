from sqlalchemy import Boolean, Column, DateTime, ForeignKey, Integer, String, Text, UniqueConstraint
from sqlalchemy.orm import relationship
from app.core.database import Base
from app.models.base import TimestampMixin, UUIDMixin


class SocialPlatform(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "social_platforms"

    identifier = Column(String(32), unique=True, index=True, nullable=False)  # linkedin, facebook, instagram, youtube, x, whatsapp, telegram
    name = Column(String(64), nullable=False)
    description = Column(String(255), nullable=True)
    is_active = Column(Boolean, default=True, nullable=False)

    # Relationships
    capabilities = relationship("PlatformCapability", back_populates="platform", cascade="all, delete-orphan")


class PlatformCapability(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "platform_capabilities"

    platform_identifier = Column(String(32), ForeignKey("social_platforms.identifier", ondelete="CASCADE"), nullable=False, index=True)
    capability_code = Column(String(64), nullable=False)  # direct_publish, video, carousel, reels, analytics, webhooks
    is_supported = Column(Boolean, default=True, nullable=False)
    description = Column(String(255), nullable=True)

    # Relationships
    platform = relationship("SocialPlatform", back_populates="capabilities")


class SocialAccount(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "social_accounts"
    __table_args__ = (
        UniqueConstraint("workspace_id", "platform", "platform_account_id", name="uq_workspace_platform_account"),
    )

    workspace_id = Column(String(36), ForeignKey("workspaces.id", ondelete="CASCADE"), nullable=False, index=True)
    platform = Column(String(32), nullable=False, index=True)  # linkedin, facebook, instagram, youtube, x, whatsapp, telegram
    account_name = Column(String(255), nullable=False)
    platform_account_id = Column(String(255), nullable=False, index=True)
    account_type = Column(String(64), default="profile", nullable=False)  # page, profile, channel, group, business
    profile_image_url = Column(String(512), nullable=True)
    follower_count = Column(Integer, default=0, nullable=False)
    connection_status = Column(String(32), default="connected", nullable=False)  # connected, expired, disconnected, error
    last_sync_at = Column(DateTime(timezone=True), nullable=True)

    # Relationships
    workspace = relationship("Workspace", back_populates="social_accounts")
    credentials = relationship("SocialAccountCredential", back_populates="account", uselist=False, cascade="all, delete-orphan")
    permissions = relationship("SocialAccountPermission", back_populates="account", cascade="all, delete-orphan")
    targets = relationship("PostTarget", back_populates="account", cascade="all, delete-orphan")
    analytics_snapshots = relationship("AnalyticsSnapshot", back_populates="account", cascade="all, delete-orphan")


class SocialAccountCredential(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "social_account_credentials"

    account_id = Column(String(36), ForeignKey("social_accounts.id", ondelete="CASCADE"), unique=True, nullable=False)
    encrypted_access_token = Column(Text, nullable=False)
    encrypted_refresh_token = Column(Text, nullable=True)
    encrypted_token_secret = Column(Text, nullable=True)
    token_expires_at = Column(DateTime(timezone=True), nullable=True)
    encryption_algorithm = Column(String(32), default="fernet-aes128-cbc", nullable=False)

    # Relationships
    account = relationship("SocialAccount", back_populates="credentials")


class SocialAccountPermission(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "social_account_permissions"

    account_id = Column(String(36), ForeignKey("social_accounts.id", ondelete="CASCADE"), nullable=False, index=True)
    scope = Column(String(128), nullable=False)
    is_granted = Column(Boolean, default=True, nullable=False)

    # Relationships
    account = relationship("SocialAccount", back_populates="permissions")


class OAuthState(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "oauth_states"

    state_token = Column(String(128), unique=True, index=True, nullable=False)
    workspace_id = Column(String(36), ForeignKey("workspaces.id", ondelete="CASCADE"), nullable=False)
    platform = Column(String(32), nullable=False)
    redirect_uri = Column(String(512), nullable=False)
    code_verifier = Column(String(128), nullable=True)  # PKCE verifier for X & LinkedIn
    expires_at = Column(DateTime(timezone=True), nullable=False)


class WebhookSubscription(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "webhook_subscriptions"

    workspace_id = Column(String(36), ForeignKey("workspaces.id", ondelete="CASCADE"), nullable=False, index=True)
    platform = Column(String(32), nullable=False, index=True)  # whatsapp, facebook, instagram, telegram
    subscription_id = Column(String(255), nullable=True)
    endpoint_url = Column(String(512), nullable=False)
    secret = Column(String(255), nullable=True)
    status = Column(String(32), default="active", nullable=False)  # active, paused, failed
    event_types = Column(Text, nullable=True)
    last_event_at = Column(DateTime(timezone=True), nullable=True)


class IntegrationEvent(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "integration_events"

    workspace_id = Column(String(36), ForeignKey("workspaces.id", ondelete="CASCADE"), nullable=True, index=True)
    platform = Column(String(32), nullable=False, index=True)
    event_type = Column(String(128), nullable=False, index=True)
    payload_json = Column(Text, nullable=False)
    processed_at = Column(DateTime(timezone=True), nullable=True)
    status = Column(String(32), default="received", nullable=False)  # received, processed, failed, ignored
    error_details = Column(Text, nullable=True)


class IntegrationSyncLog(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "integration_sync_logs"

    account_id = Column(String(36), ForeignKey("social_accounts.id", ondelete="CASCADE"), nullable=False, index=True)
    sync_type = Column(String(64), nullable=False)  # profile, followers, permissions, test_connection
    status = Column(String(32), nullable=False)  # success, failed, rate_limited
    details = Column(Text, nullable=True)


