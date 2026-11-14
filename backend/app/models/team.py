from sqlalchemy import Boolean, Column, ForeignKey, String, Text, UniqueConstraint
from sqlalchemy.orm import relationship
from app.core.database import Base
from app.models.base import TimestampMixin, UUIDMixin


class WorkspaceRole(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "workspace_roles"

    workspace_id = Column(String(36), ForeignKey("workspaces.id", ondelete="CASCADE"), nullable=True, index=True)
    role_name = Column(String(64), nullable=False)
    description = Column(String(255), nullable=True)
    is_system_role = Column(Boolean, default=False, nullable=False)

    # Relationships
    permissions = relationship("RolePermission", back_populates="role", cascade="all, delete-orphan")


class Permission(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "permissions"

    code = Column(String(64), unique=True, index=True, nullable=False)  # post.create, post.publish, account.connect, etc.
    category = Column(String(32), nullable=False)  # publishing, accounts, team, analytics, billing
    description = Column(String(255), nullable=True)


class RolePermission(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "role_permissions"
    __table_args__ = (
        UniqueConstraint("role_id", "permission_code", name="uq_role_permission"),
    )

    role_id = Column(String(36), ForeignKey("workspace_roles.id", ondelete="CASCADE"), nullable=False, index=True)
    permission_code = Column(String(64), ForeignKey("permissions.code", ondelete="CASCADE"), nullable=False)

    # Relationships
    role = relationship("WorkspaceRole", back_populates="permissions")


class PostApproval(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "post_approvals"

    post_id = Column(String(36), ForeignKey("posts.id", ondelete="CASCADE"), nullable=False, index=True)
    reviewer_user_id = Column(String(36), ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    status = Column(String(32), default="pending", nullable=False)  # pending, approved, rejected, changes_requested
    comments = Column(Text, nullable=True)

    # Relationships
    post = relationship("Post", back_populates="approvals")

