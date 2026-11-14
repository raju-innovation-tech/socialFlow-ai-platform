from typing import List
from fastapi import APIRouter, Depends, File, Form, Query, UploadFile, status
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.schemas.media import MediaAssetResponse
from app.services.media_service import MediaService

router = APIRouter(prefix="/media", tags=["Media"])


@router.get("", response_model=List[MediaAssetResponse])
def list_media(
    workspace_id: str = Query(..., description="Workspace ID"),
    skip: int = 0,
    limit: int = 50,
    db: Session = Depends(get_db),
):
    """List uploaded media assets for a workspace."""
    service = MediaService(db)
    return service.list_media(workspace_id, skip=skip, limit=limit)


@router.post("/upload", response_model=MediaAssetResponse, status_code=status.HTTP_201_CREATED)
def upload_media(
    workspace_id: str = Form(...),
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
):
    """Upload and validate media asset (safe local storage with MIME & size validation)."""
    service = MediaService(db)
    return service.upload_media(workspace_id, file)


@router.get("/{media_id}", response_model=MediaAssetResponse)
def get_media(media_id: str, db: Session = Depends(get_db)):
    """Get single media metadata."""
    service = MediaService(db)
    return service.get_media(media_id)


@router.delete("/{media_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_media(media_id: str, db: Session = Depends(get_db)):
    """Delete a media asset and remove file from storage."""
    service = MediaService(db)
    service.delete_media(media_id)
    return None

