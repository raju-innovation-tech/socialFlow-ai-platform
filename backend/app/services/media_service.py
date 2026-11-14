from fastapi import UploadFile
from sqlalchemy.orm import Session
from app.core.exceptions import NotFoundException
from app.models.media import MediaAsset
from app.repositories.media_repo import MediaRepository
from app.utils.storage import storage_service


class MediaService:
    def __init__(self, db: Session):
        self.db = db
        self.repo = MediaRepository(db)

    def list_media(self, workspace_id: str, skip: int = 0, limit: int = 50):
        return self.repo.list_by_workspace(workspace_id, skip=skip, limit=limit)

    def get_media(self, media_id: str) -> MediaAsset:
        asset = self.repo.get_by_id(media_id)
        if not asset:
            raise NotFoundException("MediaAsset", media_id)
        return asset

    def upload_media(self, workspace_id: str, file: UploadFile) -> MediaAsset:
        saved_path, file_size, file_hash = storage_service.save_upload(file)

        file_type = "image"
        if file.content_type.startswith("video"):
            file_type = "video"
        elif file.content_type.startswith("application"):
            file_type = "document"

        asset = MediaAsset(
            workspace_id=workspace_id,
            file_name=file.filename or "uploaded_media",
            file_type=file_type,
            mime_type=file.content_type or "application/octet-stream",
            file_size_bytes=file_size,
            storage_path=saved_path,
            storage_provider="local",
            file_hash=file_hash,
            upload_status="completed",
        )
        return self.repo.create(asset)

    def delete_media(self, media_id: str) -> bool:
        asset = self.get_media(media_id)
        storage_service.delete_file(asset.storage_path)
        return self.repo.delete(asset)

