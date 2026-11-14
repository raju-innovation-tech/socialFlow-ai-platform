from sqlalchemy import Boolean, Column, DateTime, ForeignKey, String, Text
from sqlalchemy.orm import relationship
from app.core.database import Base
from app.models.base import TimestampMixin, UUIDMixin


class Notification(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "notifications"

    workspace_id = Column(String(36), ForeignKey("workspaces.id", ondelete="CASCADE"), nullable=False, index=True)
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)

    title = Column(String(255), nullable=False)
    message = Column(Text, nullable=False)
    notification_type = Column(String(32), default="system", nullable=False)  # publishing, approval, alert, system, account
    is_read = Column(Boolean, default=False, nullable=False, index=True)
    metadata_json = Column(Text, nullable=True)

    # Relationships
    workspace = relationship("Workspace", back_populates="notifications")
    user = relationship("User", back_populates="notifications")
    delivery_logs = relationship("NotificationDeliveryLog", back_populates="notification", cascade="all, delete-orphan")


class NotificationPreference(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "notification_preferences"

    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    channel = Column(String(32), default="in_app", nullable=False)  # in_app, email, push
    category = Column(String(32), default="all", nullable=False)  # publishing, account, team, analytics, system
    is_enabled = Column(Boolean, default=True, nullable=False)


class NotificationDeliveryLog(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "notification_delivery_logs"

    notification_id = Column(String(36), ForeignKey("notifications.id", ondelete="CASCADE"), nullable=False, index=True)
    channel = Column(String(32), nullable=False)
    delivery_status = Column(String(32), default="sent", nullable=False)  # sent, failed, pending
    delivered_at = Column(DateTime(timezone=True), nullable=True)
    error_message = Column(Text, nullable=True)

    # Relationships
    notification = relationship("Notification", back_populates="delivery_logs")


class NotificationDevice(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "notification_devices"

    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    device_token = Column(String(255), nullable=False, index=True)
    device_type = Column(String(32), default="android", nullable=False)  # android, ios, web
    is_active = Column(Boolean, default=True, nullable=False)
