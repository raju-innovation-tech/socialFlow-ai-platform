from typing import List, Optional
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.schemas.post import PostCreate, PostResponse, PostUpdate
from app.services.post_service import PostService

router = APIRouter(prefix="/posts", tags=["Posts"])


@router.get("", response_model=List[PostResponse])
def list_posts(
    workspace_id: str = Query(..., description="Workspace ID"),
    status_filter: Optional[str] = Query(None, alias="status", description="Filter by post status"),
    skip: int = 0,
    limit: int = 50,
    db: Session = Depends(get_db),
):
    """List posts for a workspace with optional status filter."""
    service = PostService(db)
    return service.list_posts(workspace_id, status=status_filter, skip=skip, limit=limit)


@router.post("", response_model=PostResponse, status_code=status.HTTP_201_CREATED)
def create_post(payload: PostCreate, db: Session = Depends(get_db)):
    """Create a new draft or scheduled post with target platforms and variants."""
    service = PostService(db)
    return service.create_post(payload)


@router.get("/{post_id}", response_model=PostResponse)
def get_post(post_id: str, db: Session = Depends(get_db)):
    """Get single post details."""
    service = PostService(db)
    return service.get_post(post_id)


@router.put("/{post_id}", response_model=PostResponse)
def update_post(post_id: str, payload: PostUpdate, db: Session = Depends(get_db)):
    """Update post title, content, status, or schedule."""
    service = PostService(db)
    return service.update_post(post_id, payload)


@router.delete("/{post_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_post(post_id: str, db: Session = Depends(get_db)):
    """Delete a post."""
    service = PostService(db)
    service.delete_post(post_id)
    return None

