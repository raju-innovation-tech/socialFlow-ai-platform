from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field, ConfigDict


class MediaAssetResponse(BaseModel):
    id: str
    workspace_id: str
    file_name: str
    file_type: str
    mime_type: str
    file_size_bytes: int
    storage_path: str
    upload_status: str
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class MediaFolderCreate(BaseModel):
    workspace_id: str
    name: str = Field(..., min_length=1, max_length=128)
    parent_id: Optional[str] = None
    color_hex: str = "#6C8CFF"


class MediaFolderResponse(BaseModel):
    id: str
    workspace_id: str
    parent_id: Optional[str] = None
    name: str
    color_hex: str
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)

