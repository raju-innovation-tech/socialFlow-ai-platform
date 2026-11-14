from typing import List
from sqlalchemy.orm import Session
from app.models.notification import NotificationPreference
from app.schemas.notification import NotificationPreferenceUpdate


DEFAULT_CATEGORIES = ["publishing", "account", "team", "analytics", "system"]
DEFAULT_CHANNELS = ["in_app", "email", "push"]


class NotificationPreferenceService:
    def __init__(self, db: Session):
        self.db = db

    def get_user_preferences(self, user_id: str) -> List[NotificationPreference]:
        """Fetch all notification preferences for a user, initializing defaults if empty."""
        prefs = self.db.query(NotificationPreference).filter(NotificationPreference.user_id == user_id).all()
        if not prefs:
            # Seed default preferences: all enabled
            created = []
            for channel in DEFAULT_CHANNELS:
                for cat in DEFAULT_CATEGORIES:
                    pref = NotificationPreference(
                        user_id=user_id,
                        channel=channel,
                        category=cat,
                        is_enabled=True,
                    )
                    self.db.add(pref)
                    created.append(pref)
            self.db.commit()
            for p in created:
                self.db.refresh(p)
            return created
        return prefs

    def update_preference(self, user_id: str, update: NotificationPreferenceUpdate) -> NotificationPreference:
        """Update or insert a channel/category preference setting for a user."""
        pref = (
            self.db.query(NotificationPreference)
            .filter(
                NotificationPreference.user_id == user_id,
                NotificationPreference.channel == update.channel,
                NotificationPreference.category == update.category,
            )
            .first()
        )
        if pref:
            pref.is_enabled = update.is_enabled
        else:
            pref = NotificationPreference(
                user_id=user_id,
                channel=update.channel,
                category=update.category,
                is_enabled=update.is_enabled,
            )
            self.db.add(pref)

        self.db.commit()
        self.db.refresh(pref)
        return pref

    def is_channel_enabled(self, user_id: str, channel: str, category: str) -> bool:
        """Check whether a user allows notifications for a specific channel and category."""
        pref = (
            self.db.query(NotificationPreference)
            .filter(
                NotificationPreference.user_id == user_id,
                NotificationPreference.channel == channel,
                NotificationPreference.category == category,
            )
            .first()
        )
        if pref:
            return pref.is_enabled
        return True  # default enabled

