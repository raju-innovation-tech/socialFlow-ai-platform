import uuid
from datetime import datetime, timezone
from sqlalchemy import Boolean, Column, DateTime, ForeignKey, Integer, String, Text
from sqlalchemy.orm import relationship
from app.core.database import Base
from app.models.base import TimestampMixin, UUIDMixin, utc_now


class RefreshToken(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "refresh_tokens"

    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    token_hash = Column(String(128), unique=True, index=True, nullable=False)
    token_family = Column(String(64), index=True, nullable=False)  # UUID for family tracking & reuse detection
    expires_at = Column(DateTime(timezone=True), nullable=False, index=True)
    revoked_at = Column(DateTime(timezone=True), nullable=True)
    is_used = Column(Boolean, default=False, nullable=False)

    # Relationships
    user = relationship("User", back_populates="refresh_tokens")
    session = relationship("UserSession", back_populates="refresh_token", uselist=False)


class UserSession(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "user_sessions"

    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    refresh_token_id = Column(String(36), ForeignKey("refresh_tokens.id", ondelete="SET NULL"), nullable=True)
    ip_address = Column(String(45), nullable=True)
    user_agent = Column(String(255), nullable=True)
    expires_at = Column(DateTime(timezone=True), nullable=False)
    is_revoked = Column(Boolean, default=False, nullable=False)

    # Relationships
    user = relationship("User", back_populates="sessions")
    refresh_token = relationship("RefreshToken", back_populates="session")


class EmailVerificationToken(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "email_verification_tokens"

    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    otp_hash = Column(String(128), index=True, nullable=False)  # SHA-256 of 6-digit OTP
    attempts_count = Column(Integer, default=0, nullable=False)
    max_attempts = Column(Integer, default=3, nullable=False)
    expires_at = Column(DateTime(timezone=True), nullable=False, index=True)
    is_used = Column(Boolean, default=False, nullable=False)

    # Relationships
    user = relationship("User", back_populates="email_verifications")


class PasswordResetToken(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "password_reset_tokens"

    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    token_hash = Column(String(128), unique=True, index=True, nullable=False)
    expires_at = Column(DateTime(timezone=True), nullable=False, index=True)
    is_used = Column(Boolean, default=False, nullable=False)

    # Relationships
    user = relationship("User", back_populates="password_resets")


class LoginAttempt(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "login_attempts"

    email = Column(String(255), index=True, nullable=False)
    ip_address = Column(String(45), nullable=True, index=True)
    success = Column(Boolean, default=False, nullable=False)
    attempted_at = Column(DateTime(timezone=True), default=utc_now, nullable=False)


class PlatformRole(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "platform_roles"

    role_name = Column(String(64), unique=True, index=True, nullable=False)  # SUPER_ADMIN
    description = Column(String(255), nullable=True)

    permissions = relationship("PlatformRolePermission", back_populates="platform_role", cascade="all, delete-orphan")


class PlatformRolePermission(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "platform_role_permissions"

    platform_role_id = Column(String(36), ForeignKey("platform_roles.id", ondelete="CASCADE"), nullable=False, index=True)
    permission_code = Column(String(64), nullable=False)  # platform.users.manage, platform.workspaces.manage, etc.

    platform_role = relationship("PlatformRole", back_populates="permissions")

