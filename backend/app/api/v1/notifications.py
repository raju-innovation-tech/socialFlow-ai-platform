from typing import List
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.core.deps import get_active_workspace_member
from app.core.exceptions import ForbiddenException, NotFoundException
from app.models.membership import WorkspaceMember
from app.models.notification import Notification
from app.schemas.notification import NotificationResponse

router = APIRouter(prefix="/notifications", tags=["Notifications"])


@router.get("", response_model=List[NotificationResponse])
def list_notifications(
    unread_only: bool = Query(False),
    member: WorkspaceMember = Depends(get_active_workspace_member),
    db: Session = Depends(get_db),
):
    """List in-app notifications strictly for the active workspace."""
    query = db.query(Notification).filter(Notification.workspace_id == member.workspace_id)
    if unread_only:
        query = query.filter(Notification.is_read == False)
    return query.order_by(Notification.created_at.desc()).limit(50).all()


@router.get("/{notification_id}", response_model=NotificationResponse)
def get_notification(
    notification_id: str,
    member: WorkspaceMember = Depends(get_active_workspace_member),
    db: Session = Depends(get_db),
):
    """Get single notification details with tenant verification and mark as read."""
    n = db.query(Notification).filter(Notification.id == notification_id).first()
    if not n:
        raise NotFoundException("Notification", notification_id)
    if n.workspace_id != member.workspace_id:
        raise ForbiddenException("Cross-tenant access prohibited.")

    if not n.is_read:
        n.is_read = True
        db.commit()
        db.refresh(n)
    return n
