from typing import List
from fastapi import APIRouter, Depends, File, UploadFile, status
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.core.deps import require_permission
from app.core.exceptions import ForbiddenException
from app.models.membership import WorkspaceMember
from app.schemas.media import MediaAssetResponse
from app.services.media_service import MediaService

router = APIRouter(prefix="/media", tags=["Media"])


@router.get("", response_model=List[MediaAssetResponse])
def list_media(
    skip: int = 0,
    limit: int = 50,
    member: WorkspaceMember = Depends(require_permission("media.view")),
    db: Session = Depends(get_db),
):
    """List uploaded media assets strictly for active workspace."""
    service = MediaService(db)
    return service.list_media(member.workspace_id, skip=skip, limit=limit)


@router.post("/upload", response_model=MediaAssetResponse, status_code=status.HTTP_201_CREATED)
def upload_media(
    file: UploadFile = File(...),
    member: WorkspaceMember = Depends(require_permission("media.upload")),
    db: Session = Depends(get_db),
):
    """Upload and validate media asset within active workspace."""
    service = MediaService(db)
    return service.upload_media(member.workspace_id, file)


@router.get("/{media_id}", response_model=MediaAssetResponse)
def get_media(
    media_id: str,
    member: WorkspaceMember = Depends(require_permission("media.view")),
    db: Session = Depends(get_db),
):
    """Get single media metadata with tenant ownership check."""
    service = MediaService(db)
    asset = service.get_media(media_id)
    if asset.workspace_id != member.workspace_id:
        raise ForbiddenException("Cross-tenant access prohibited.")
    return asset


@router.delete("/{media_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_media(
    media_id: str,
    member: WorkspaceMember = Depends(require_permission("media.delete")),
    db: Session = Depends(get_db),
):
    """Delete media asset with tenant check."""
    service = MediaService(db)
    asset = service.get_media(media_id)
    if asset.workspace_id != member.workspace_id:
        raise ForbiddenException("Cross-tenant deletion prohibited.")
    service.delete_media(media_id)
    return None
