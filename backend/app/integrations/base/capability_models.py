from enum import Enum
from typing import Any, Dict, List, Optional
from pydantic import BaseModel, Field


class CapabilityStatus(str, Enum):
    SUPPORTED = "supported"
    REQUIRES_PERMISSION = "requires_permission"
    REQUIRES_ACCOUNT_ELIGIBILITY = "requires_account_eligibility"
    RESTRICTED = "restricted"
    MANUAL_ONLY = "manual_only"
    UNAVAILABLE = "unavailable"
    NOT_IMPLEMENTED = "not_implemented"


class CapabilityCategory(str, Enum):
    AUTHENTICATION = "authentication"
    PROFILE = "profile"
    PUBLISHING = "publishing"
    MEDIA = "media"
    ANALYTICS = "analytics"
    WEBHOOKS = "webhooks"
    COMMUNITY = "community"


class PlatformCapabilityModel(BaseModel):
    code: str
    name: str
    category: CapabilityCategory
    status: CapabilityStatus
    notes: Optional[str] = None
    doc_url: Optional[str] = None


class AccountProfile(BaseModel):
    platform_account_id: str
    username: str
    display_name: str
    account_type: str = "profile"  # profile, page, channel, business, bot
    profile_image_url: Optional[str] = None
    follower_count: int = 0
    email: Optional[str] = None
    metadata: Dict[str, Any] = Field(default_factory=dict)


class DiscoveredChannel(BaseModel):
    channel_id: str
    name: str
    category: str = "page"  # page, channel, group, business_account
    avatar_url: Optional[str] = None
    access_token: Optional[str] = None
    is_eligible: bool = True
    eligibility_reason: Optional[str] = None


class TokenBundle(BaseModel):
    access_token: str
    refresh_token: Optional[str] = None
    token_secret: Optional[str] = None
    expires_in: Optional[int] = None
    scopes: List[str] = Field(default_factory=list)
    raw_response: Dict[str, Any] = Field(default_factory=dict)

