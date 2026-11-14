from datetime import datetime
from typing import Any, Dict, List, Optional
from pydantic import BaseModel, ConfigDict, Field


class PostVariantSchema(BaseModel):
    platform: str
    customized_content: str


class PostVariantResponse(PostVariantSchema):
    id: str
    post_id: str
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class PostTargetSchema(BaseModel):
    social_account_id: str


class PostTargetResponse(BaseModel):
    id: str
    post_id: str
    social_account_id: str
    status: str
    external_post_id: Optional[str] = None
    error_message: Optional[str] = None
    published_at: Optional[datetime] = None
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class PostBase(BaseModel):
    title: Optional[str] = Field(None, max_length=255)
    content: str = Field(..., min_length=1)
    content_type: str = Field(default="text", pattern="^(text|image|video|carousel|reel|poll)$")
    scheduled_at: Optional[datetime] = None


class PostCreate(PostBase):
    workspace_id: str
    category_id: Optional[str] = None
    target_account_ids: Optional[List[str]] = Field(default_factory=list)
    variants: Optional[List[PostVariantSchema]] = Field(default_factory=list)
    media_asset_ids: Optional[List[str]] = Field(default_factory=list)


class PostUpdate(BaseModel):
    title: Optional[str] = None
    content: Optional[str] = None
    content_type: Optional[str] = None
    status: Optional[str] = None
    scheduled_at: Optional[datetime] = None
    category_id: Optional[str] = None
    target_account_ids: Optional[List[str]] = None
    variants: Optional[List[PostVariantSchema]] = None
    media_asset_ids: Optional[List[str]] = None


class PostResponse(PostBase):
    id: str
    workspace_id: str
    category_id: Optional[str] = None
    status: str
    published_at: Optional[datetime] = None
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


class PostDetailResponse(PostResponse):
    targets: List[PostTargetResponse] = Field(default_factory=list)
    variants: List[PostVariantResponse] = Field(default_factory=list)
    media_asset_ids: List[str] = Field(default_factory=list)


class SchedulePostRequest(BaseModel):
    scheduled_at: datetime
    timezone: str = "UTC"


class ValidatePostRequest(BaseModel):
    content: str = Field(..., min_length=1)
    platforms: List[str] = Field(..., min_length=1)
    variants: Optional[Dict[str, str]] = None
    media_asset_ids: Optional[List[str]] = None


class PublishingStatusResponse(BaseModel):
    post_id: str
    status: str
    scheduled_at: Optional[datetime] = None
    published_at: Optional[datetime] = None
    targets: List[Dict[str, Any]] = Field(default_factory=list)
