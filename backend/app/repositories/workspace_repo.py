from typing import List, Optional
from sqlalchemy.orm import Session
from app.models.workspace import Workspace
from app.repositories.base import BaseRepository


class WorkspaceRepository(BaseRepository[Workspace]):
    def __init__(self, db: Session):
        super().__init__(Workspace, db)

    def get_by_slug(self, slug: str) -> Optional[Workspace]:
        return self.db.query(Workspace).filter(Workspace.slug == slug).first()

    def list_active(self, skip: int = 0, limit: int = 50) -> List[Workspace]:
        return (
            self.db.query(Workspace)
            .filter(Workspace.is_active == True)
            .order_by(Workspace.created_at.desc())
            .offset(skip)
            .limit(limit)
            .all()
        )

