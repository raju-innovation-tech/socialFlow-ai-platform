from sqlalchemy import Column, DateTime, ForeignKey, String, UniqueConstraint
from sqlalchemy.orm import relationship
from app.core.database import Base
from app.models.base import TimestampMixin, UUIDMixin


class WorkspaceMember(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "workspace_members"
    __table_args__ = (
        UniqueConstraint("workspace_id", "user_id", name="uq_workspace_user_membership"),
    )

    workspace_id = Column(String(36), ForeignKey("workspaces.id", ondelete="CASCADE"), nullable=False, index=True)
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    role = Column(String(32), default="editor", nullable=False)  # owner, admin, editor, approver, analyst, viewer
    status = Column(String(32), default="active", nullable=False)  # active, suspended, invited

    # Relationships
    workspace = relationship("Workspace", back_populates="members")
    user = relationship("User", back_populates="memberships")


class WorkspaceInvitation(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "workspace_invitations"

    workspace_id = Column(String(36), ForeignKey("workspaces.id", ondelete="CASCADE"), nullable=False, index=True)
    email = Column(String(255), nullable=False, index=True)
    role = Column(String(32), default="editor", nullable=False)
    token = Column(String(128), unique=True, index=True, nullable=False)
    status = Column(String(32), default="pending", nullable=False)  # pending, accepted, expired, revoked
    expires_at = Column(DateTime(timezone=True), nullable=False)

    # Relationships
    workspace = relationship("Workspace", back_populates="invitations")

