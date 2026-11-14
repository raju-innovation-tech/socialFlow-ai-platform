from typing import List
from sqlalchemy.orm import Session
from app.models.notification import Notification
from app.repositories.base import BaseRepository


class NotificationRepository(BaseRepository[Notification]):
    def __init__(self, db: Session):
        super().__init__(Notification, db)

    def list_by_workspace(self, workspace_id: str, unread_only: bool = False, limit: int = 50) -> List[Notification]:
        query = self.db.query(Notification).filter(Notification.workspace_id == workspace_id)
        if unread_only:
            query = query.filter(Notification.is_read == False)
        return query.order_by(Notification.created_at.desc()).limit(limit).all()

    def mark_all_as_read(self, workspace_id: str) -> int:
        count = (
            self.db.query(Notification)
            .filter(Notification.workspace_id == workspace_id, Notification.is_read == False)
            .update({"is_read": True})
        )
        self.db.commit()
        return count

