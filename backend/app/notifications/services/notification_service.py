import json
import logging
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional
from sqlalchemy.orm import Session

from app.core.exceptions import ForbiddenException, NotFoundException
from app.models.notification import (
    Notification,
    NotificationDeliveryLog,
    NotificationDevice,
)
from app.notifications.services.preference_service import NotificationPreferenceService

logger = logging.getLogger(__name__)


class NotificationService:
    def __init__(self, db: Session):
        self.db = db
        self.pref_service = NotificationPreferenceService(db)

    def list_notifications(
        self,
        workspace_id: str,
        user_id: Optional[str] = None,
        unread_only: bool = False,
        limit: int = 50,
    ) -> List[Notification]:
        """Fetch notifications strictly scoped to workspace and optionally user."""
        query = self.db.query(Notification).filter(Notification.workspace_id == workspace_id)
        if user_id:
            query = query.filter(Notification.user_id == user_id)
        if unread_only:
            query = query.filter(Notification.is_read == False)
        return query.order_by(Notification.created_at.desc()).limit(limit).all()

    def get_unread_count(self, workspace_id: str, user_id: Optional[str] = None) -> int:
        """Get total unread notifications count for badge display."""
        query = self.db.query(Notification).filter(
            Notification.workspace_id == workspace_id,
            Notification.is_read == False,
        )
        if user_id:
            query = query.filter(Notification.user_id == user_id)
        return query.count()

    def mark_as_read(self, notification_id: str, workspace_id: str) -> Notification:
        """Mark single notification as read with tenant boundary check."""
        n = self.db.query(Notification).filter(Notification.id == notification_id).first()
        if not n:
            raise NotFoundException("Notification", notification_id)
        if n.workspace_id != workspace_id:
            raise ForbiddenException("Cross-tenant access prohibited.")

        n.is_read = True
        self.db.commit()
        self.db.refresh(n)
        return n

    def mark_all_as_read(self, workspace_id: str, user_id: Optional[str] = None) -> int:
        """Mark all unread notifications in workspace as read."""
        query = self.db.query(Notification).filter(
            Notification.workspace_id == workspace_id,
            Notification.is_read == False,
        )
        if user_id:
            query = query.filter(Notification.user_id == user_id)

        count = query.update({"is_read": True}, synchronize_session=False)
        self.db.commit()
        return count

    def delete_notification(self, notification_id: str, workspace_id: str) -> bool:
        """Delete notification with tenant boundary check."""
        n = self.db.query(Notification).filter(Notification.id == notification_id).first()
        if not n:
            raise NotFoundException("Notification", notification_id)
        if n.workspace_id != workspace_id:
            raise ForbiddenException("Cross-tenant access prohibited.")

        self.db.delete(n)
        self.db.commit()
        return True

    def create_notification(
        self,
        workspace_id: str,
        user_id: str,
        title: str,
        message: str,
        notification_type: str = "system",
        metadata: Optional[Dict[str, Any]] = None,
    ) -> Notification:
        """Create and dispatch multi-channel notification honoring user preferences."""
        meta_str = json.dumps(metadata) if metadata else None
        notification = Notification(
            workspace_id=workspace_id,
            user_id=user_id,
            title=title,
            message=message,
            notification_type=notification_type,
            is_read=False,
            metadata_json=meta_str,
        )
        self.db.add(notification)
        self.db.flush()

        # Multi-channel delivery logs based on user preferences
        # 1. In-App Channel
        if self.pref_service.is_channel_enabled(user_id, "in_app", notification_type):
            self.db.add(
                NotificationDeliveryLog(
                    notification_id=notification.id,
                    channel="in_app",
                    delivery_status="sent",
                    delivered_at=datetime.now(timezone.utc),
                )
            )

        # 2. Email Channel
        if self.pref_service.is_channel_enabled(user_id, "email", notification_type):
            self.db.add(
                NotificationDeliveryLog(
                    notification_id=notification.id,
                    channel="email",
                    delivery_status="sent",
                    delivered_at=datetime.now(timezone.utc),
                )
            )

        # 3. Push Channel (check if user has registered active devices)
        if self.pref_service.is_channel_enabled(user_id, "push", notification_type):
            devices = (
                self.db.query(NotificationDevice)
                .filter(NotificationDevice.user_id == user_id, NotificationDevice.is_active == True)
                .all()
            )
            status = "sent" if devices else "pending"
            self.db.add(
                NotificationDeliveryLog(
                    notification_id=notification.id,
                    channel="push",
                    delivery_status=status,
                    delivered_at=datetime.now(timezone.utc) if devices else None,
                    error_message=None if devices else "No active device tokens found",
                )
            )

        self.db.commit()
        self.db.refresh(notification)
        return notification

    def register_device(self, user_id: str, device_token: str, device_type: str = "android") -> NotificationDevice:
        """Register or update an FCM/APNs device push token."""
        existing = (
            self.db.query(NotificationDevice)
            .filter(NotificationDevice.user_id == user_id, NotificationDevice.device_token == device_token)
            .first()
        )
        if existing:
            existing.device_type = device_type
            existing.is_active = True
            self.db.commit()
            self.db.refresh(existing)
            return existing

        device = NotificationDevice(
            user_id=user_id,
            device_token=device_token,
            device_type=device_type,
            is_active=True,
        )
        self.db.add(device)
        self.db.commit()
        self.db.refresh(device)
        return device

    # Event Dispatchers Matching Image Requirements
    def notify_post_published(self, workspace_id: str, user_id: str, post_title: str, platform: str):
        return self.create_notification(
            workspace_id=workspace_id,
            user_id=user_id,
            title="Post successfully published",
            message=f'Your post "{post_title}" was successfully published to {platform.capitalize()}.',
            notification_type="publishing",
            metadata={"status": "success", "platform": platform},
        )

    def notify_token_expired(self, workspace_id: str, user_id: str, platform: str, account_name: str):
        return self.create_notification(
            workspace_id=workspace_id,
            user_id=user_id,
            title=f"{platform.capitalize()} authorization expired",
            message=f'Access token for {account_name} on {platform.capitalize()} has expired. Please reconnect to resume publishing.',
            notification_type="account",
            metadata={"status": "action_required", "platform": platform, "account_name": account_name},
        )

    def notify_approval_requested(self, workspace_id: str, user_id: str, post_title: str, author_name: str):
        return self.create_notification(
            workspace_id=workspace_id,
            user_id=user_id,
            title="New post approval requested",
            message=f'{author_name} requested approval for post: "{post_title}".',
            notification_type="approval",
            metadata={"status": "new", "author": author_name},
        )

