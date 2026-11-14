from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel, Field, ConfigDict


class SocialAccountBase(BaseModel):
    platform: str = Field(..., pattern="^(linkedin|facebook|instagram|youtube|x|whatsapp|telegram)$")
    account_name: str = Field(..., min_length=1, max_length=255)
    platform_account_id: str = Field(..., min_length=1, max_length=255)
    account_type: str = "profile"
    profile_image_url: Optional[str] = None


class SocialAccountCreate(SocialAccountBase):
    workspace_id: str
    access_token: Optional[str] = None
    refresh_token: Optional[str] = None


class SocialAccountResponse(SocialAccountBase):
    id: str
    workspace_id: str
    follower_count: int
    connection_status: str
    last_sync_at: Optional[datetime] = None
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


class PlatformCapabilityResponse(BaseModel):
    platform_identifier: str
    capability_code: str
    is_supported: bool
    description: Optional[str] = None

    model_config = ConfigDict(from_attributes=True)


class TelegramConnectRequest(BaseModel):
    bot_token: str = Field(..., min_length=10, max_length=255)
    chat_id: Optional[str] = None


class WhatsAppOnboardRequest(BaseModel):
    phone_number_id: str = Field(..., min_length=5, max_length=128)
    waba_id: str = Field(..., min_length=5, max_length=128)
    access_token: str = Field(..., min_length=10)


class SelectPageRequest(BaseModel):
    channel_id: str
    channel_name: str
    access_token: str
    platform: str = Field(..., pattern="^(facebook|instagram|youtube)$")
    account_type: str = "page"
    avatar_url: Optional[str] = None


class OAuthAuthorizeResponse(BaseModel):
    platform: str
    authorization_url: str
    state: str


class SocialAccountPermissionResponse(BaseModel):
    id: str
    scope: str
    is_granted: bool

    model_config = ConfigDict(from_attributes=True)


