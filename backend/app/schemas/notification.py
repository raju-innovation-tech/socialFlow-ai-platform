from datetime import datetime
from typing import Optional
from pydantic import BaseModel, ConfigDict


class NotificationResponse(BaseModel):
    id: str
    workspace_id: str
    user_id: str
    title: str
    message: str
    notification_type: str
    is_read: bool
    created_at: datetime
    metadata_json: Optional[str] = None

    model_config = ConfigDict(from_attributes=True)


class UnreadCountResponse(BaseModel):
    unread_count: int


class NotificationPreferenceResponse(BaseModel):
    id: str
    user_id: str
    channel: str
    category: str
    is_enabled: bool

    model_config = ConfigDict(from_attributes=True)


class NotificationPreferenceUpdate(BaseModel):
    channel: str  # in_app, email, push
    category: str  # publishing, account, team, analytics, system, all
    is_enabled: bool


class DeviceTokenRegisterRequest(BaseModel):
    device_token: str
    device_type: str = "android"  # android, ios, web
