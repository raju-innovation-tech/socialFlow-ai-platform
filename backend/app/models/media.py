from sqlalchemy import Column, ForeignKey, Integer, String
from sqlalchemy.orm import relationship
from app.core.database import Base
from app.models.base import TimestampMixin, UUIDMixin


class MediaAsset(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "media_assets"

    workspace_id = Column(String(36), ForeignKey("workspaces.id", ondelete="CASCADE"), nullable=False, index=True)
    uploaded_by_user_id = Column(String(36), ForeignKey("users.id", ondelete="SET NULL"), nullable=True)

    file_name = Column(String(255), nullable=False)
    file_type = Column(String(32), default="image", nullable=False)  # image, video, document, audio
    mime_type = Column(String(128), nullable=False)
    file_size_bytes = Column(Integer, nullable=False)
    storage_path = Column(String(512), nullable=False)
    storage_provider = Column(String(32), default="local", nullable=False)  # local, s3, r2
    file_hash = Column(String(64), nullable=True, index=True)

    width = Column(Integer, nullable=True)
    height = Column(Integer, nullable=True)
    duration_seconds = Column(Integer, nullable=True)
    upload_status = Column(String(32), default="completed", nullable=False)  # pending, completed, failed

    # Relationships
    workspace = relationship("Workspace", back_populates="media_assets")
    post_links = relationship("PostMedia", back_populates="media_asset", cascade="all, delete-orphan")
    folder_links = relationship("MediaFolderItem", back_populates="media_asset", cascade="all, delete-orphan")


class MediaFolder(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "media_folders"

    workspace_id = Column(String(36), ForeignKey("workspaces.id", ondelete="CASCADE"), nullable=False, index=True)
    parent_id = Column(String(36), ForeignKey("media_folders.id", ondelete="CASCADE"), nullable=True)
    name = Column(String(128), nullable=False)
    color_hex = Column(String(7), default="#6C8CFF", nullable=False)

    # Relationships
    workspace = relationship("Workspace", back_populates="media_folders")
    items = relationship("MediaFolderItem", back_populates="folder", cascade="all, delete-orphan")


class MediaFolderItem(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "media_folder_items"

    folder_id = Column(String(36), ForeignKey("media_folders.id", ondelete="CASCADE"), nullable=False, index=True)
    media_asset_id = Column(String(36), ForeignKey("media_assets.id", ondelete="CASCADE"), nullable=False, index=True)

    # Relationships
    folder = relationship("MediaFolder", back_populates="items")
    media_asset = relationship("MediaAsset", back_populates="folder_links")

