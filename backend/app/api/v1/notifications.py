from typing import List
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.deps import get_active_workspace_member, get_current_user
from app.models.membership import WorkspaceMember
from app.models.user import User
from app.notifications.services.notification_service import NotificationService
from app.notifications.services.preference_service import NotificationPreferenceService
from app.schemas.notification import (
    DeviceTokenRegisterRequest,
    NotificationPreferenceResponse,
    NotificationPreferenceUpdate,
    NotificationResponse,
    UnreadCountResponse,
)

router = APIRouter(prefix="/notifications", tags=["Notifications"])


@router.get("", response_model=List[NotificationResponse])
def list_notifications(
    unread_only: bool = Query(False),
    member: WorkspaceMember = Depends(get_active_workspace_member),
    db: Session = Depends(get_db),
):
    """List notifications strictly scoped to the active workspace."""
    service = NotificationService(db)
    return service.list_notifications(
        workspace_id=member.workspace_id,
        unread_only=unread_only,
    )


@router.get("/unread-count", response_model=UnreadCountResponse)
def get_unread_count(
    member: WorkspaceMember = Depends(get_active_workspace_member),
    db: Session = Depends(get_db),
):
    """Get total unread notifications count for badge notification in topbar."""
    service = NotificationService(db)
    count = service.get_unread_count(
        workspace_id=member.workspace_id,
    )
    return {"unread_count": count}


@router.post("/read-all", status_code=status.HTTP_200_OK)
def mark_all_notifications_read(
    member: WorkspaceMember = Depends(get_active_workspace_member),
    db: Session = Depends(get_db),
):
    """Mark all workspace notifications as read."""
    service = NotificationService(db)
    count = service.mark_all_as_read(member.workspace_id)
    return {"updated": count, "message": "All notifications marked as read."}


@router.get("/preferences", response_model=List[NotificationPreferenceResponse])
def get_preferences(
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Retrieve current user notification channel and category preferences."""
    pref_service = NotificationPreferenceService(db)
    return pref_service.get_user_preferences(user.id)


@router.patch("/preferences", response_model=NotificationPreferenceResponse)
def update_preference(
    update: NotificationPreferenceUpdate,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Update notification preference for a specific channel and category."""
    pref_service = NotificationPreferenceService(db)
    return pref_service.update_preference(user.id, update)


@router.post("/devices/register", status_code=status.HTTP_200_OK)
def register_device_token(
    payload: DeviceTokenRegisterRequest,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Register mobile / web push device token (FCM/APNs)."""
    service = NotificationService(db)
    dev = service.register_device(user.id, payload.device_token, payload.device_type)
    return {"status": "registered", "device_id": dev.id}


@router.get("/{notification_id}", response_model=NotificationResponse)
def get_notification(
    notification_id: str,
    member: WorkspaceMember = Depends(get_active_workspace_member),
    db: Session = Depends(get_db),
):
    """Get single notification details with tenant verification and mark as read."""
    service = NotificationService(db)
    return service.mark_as_read(notification_id, member.workspace_id)


@router.patch("/{notification_id}/read", response_model=NotificationResponse)
def mark_notification_read(
    notification_id: str,
    member: WorkspaceMember = Depends(get_active_workspace_member),
    db: Session = Depends(get_db),
):
    """Mark a specific notification as read."""
    service = NotificationService(db)
    return service.mark_as_read(notification_id, member.workspace_id)


@router.delete("/{notification_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_notification(
    notification_id: str,
    member: WorkspaceMember = Depends(get_active_workspace_member),
    db: Session = Depends(get_db),
):
    """Delete a notification."""
    service = NotificationService(db)
    service.delete_notification(notification_id, member.workspace_id)
    return None
