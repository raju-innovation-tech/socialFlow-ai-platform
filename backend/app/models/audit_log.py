from sqlalchemy import Column, DateTime, ForeignKey, String, Text
from sqlalchemy.orm import relationship
from app.core.database import Base
from app.models.base import TimestampMixin, UUIDMixin, utc_now


class AuditLog(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "audit_logs"

    workspace_id = Column(String(36), ForeignKey("workspaces.id", ondelete="CASCADE"), nullable=True, index=True)
    actor_id = Column(String(36), ForeignKey("users.id", ondelete="SET NULL"), nullable=True, index=True)

    entity_type = Column(String(64), nullable=False, index=True)  # post, social_account, workspace, campaign, user
    entity_id = Column(String(64), nullable=False, index=True)
    action = Column(String(64), nullable=False, index=True)  # create, update, delete, schedule, publish_trigger
    metadata_json = Column(Text, nullable=True)  # Sanitized JSON details (no secrets/passwords)
    ip_address = Column(String(45), nullable=True)
    user_agent = Column(String(255), nullable=True)
    logged_at = Column(DateTime(timezone=True), default=utc_now, nullable=False)

    # Relationships
    workspace = relationship("Workspace", back_populates="audit_logs")
    actor = relationship("User", back_populates="audit_logs")

