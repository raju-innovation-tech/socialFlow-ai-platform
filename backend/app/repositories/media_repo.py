from typing import List
from sqlalchemy.orm import Session
from app.models.media import MediaAsset, MediaFolder
from app.repositories.base import BaseRepository


class MediaRepository(BaseRepository[MediaAsset]):
    def __init__(self, db: Session):
        super().__init__(MediaAsset, db)

    def list_by_workspace(self, workspace_id: str, skip: int = 0, limit: int = 50) -> List[MediaAsset]:
        return (
            self.db.query(MediaAsset)
            .filter(MediaAsset.workspace_id == workspace_id)
            .order_by(MediaAsset.created_at.desc())
            .offset(skip)
            .limit(limit)
            .all()
        )

    def list_folders(self, workspace_id: str) -> List[MediaFolder]:
        return (
            self.db.query(MediaFolder)
            .filter(MediaFolder.workspace_id == workspace_id)
            .order_by(MediaFolder.name.asc())
            .all()
        )

