from typing import List, Optional
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.core.deps import require_permission
from app.core.exceptions import ForbiddenException, NotFoundException
from app.models.membership import WorkspaceMember
from app.schemas.post import PostCreate, PostResponse, PostUpdate
from app.services.post_service import PostService

router = APIRouter(prefix="/posts", tags=["Posts"])


@router.get("", response_model=List[PostResponse])
def list_posts(
    status_filter: Optional[str] = Query(None, alias="status", description="Filter by post status"),
    skip: int = 0,
    limit: int = 50,
    member: WorkspaceMember = Depends(require_permission("posts.view")),
    db: Session = Depends(get_db),
):
    """List posts strictly scoped to the authenticated user's active workspace."""
    service = PostService(db)
    return service.list_posts(member.workspace_id, status=status_filter, skip=skip, limit=limit)


@router.post("", response_model=PostResponse, status_code=status.HTTP_201_CREATED)
def create_post(
    payload: PostCreate,
    member: WorkspaceMember = Depends(require_permission("posts.create")),
    db: Session = Depends(get_db),
):
    """Create a new post within the verified active workspace (IDOR protected)."""
    # Force authenticated member's workspace_id
    payload.workspace_id = member.workspace_id
    service = PostService(db)
    return service.create_post(payload)


@router.get("/{post_id}", response_model=PostResponse)
def get_post(
    post_id: str,
    member: WorkspaceMember = Depends(require_permission("posts.view")),
    db: Session = Depends(get_db),
):
    """Get single post details with tenant ownership verification."""
    service = PostService(db)
    post = service.get_post(post_id)
    if post.workspace_id != member.workspace_id:
        raise ForbiddenException("Cross-tenant access prohibited. Post does not belong to your active workspace.")
    return post


@router.put("/{post_id}", response_model=PostResponse)
def update_post(
    post_id: str,
    payload: PostUpdate,
    member: WorkspaceMember = Depends(require_permission("posts.update")),
    db: Session = Depends(get_db),
):
    """Update post with tenant isolation check."""
    service = PostService(db)
    post = service.get_post(post_id)
    if post.workspace_id != member.workspace_id:
        raise ForbiddenException("Cross-tenant mutation prohibited.")
    return service.update_post(post_id, payload)


@router.delete("/{post_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_post(
    post_id: str,
    member: WorkspaceMember = Depends(require_permission("posts.delete")),
    db: Session = Depends(get_db),
):
    """Delete post with tenant isolation check."""
    service = PostService(db)
    post = service.get_post(post_id)
    if post.workspace_id != member.workspace_id:
        raise ForbiddenException("Cross-tenant deletion prohibited.")
    service.delete_post(post_id)
    return None
