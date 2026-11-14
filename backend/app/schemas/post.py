from datetime import datetime
from typing import List, Optional
from pydantic import BaseModel, Field, ConfigDict


class PostVariantSchema(BaseModel):
    platform: str
    customized_content: str


class PostTargetSchema(BaseModel):
    social_account_id: str


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


class PostResponse(PostBase):
    id: str
    workspace_id: str
    category_id: Optional[str] = None
    status: str
    published_at: Optional[datetime] = None
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)

