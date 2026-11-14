from typing import Any, Dict, List, Optional
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.deps import require_permission
from app.core.exceptions import ForbiddenException, NotFoundException
from app.models.membership import WorkspaceMember
from app.models.post import Post, PostMedia, PostTarget, PostVariant
from app.models.social_account import SocialAccount
from app.publishing.services.publishing_service import PublishingService
from app.publishing.services.scheduling_service import SchedulingService
from app.publishing.services.validation_service import ContentValidationService
from app.schemas.post import (
    PostCreate,
    PostDetailResponse,
    PostResponse,
    PostTargetResponse,
    PostUpdate,
    PublishingStatusResponse,
    SchedulePostRequest,
    ValidatePostRequest,
)
from app.services.post_service import PostService

router = APIRouter(prefix="/posts", tags=["Posts & Publishing"])


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
    payload.workspace_id = member.workspace_id
    service = PostService(db)
    return service.create_post(payload)


@router.post("/validate")
def validate_post_content(
    payload: ValidatePostRequest,
    member: WorkspaceMember = Depends(require_permission("posts.create")),
):
    """Validate content, character limits, and media attachments across selected platforms."""
    return ContentValidationService.validate_for_platforms(
        base_content=payload.content,
        platforms=payload.platforms,
        platform_variants=payload.variants,
    )


@router.get("/{post_id}", response_model=PostDetailResponse)
def get_post(
    post_id: str,
    member: WorkspaceMember = Depends(require_permission("posts.view")),
    db: Session = Depends(get_db),
):
    """Get single post details with targets and variants."""
    service = PostService(db)
    post = service.get_post(post_id)
    if post.workspace_id != member.workspace_id:
        raise ForbiddenException("Cross-tenant access prohibited.")

    targets = db.query(PostTarget).filter(PostTarget.post_id == post.id).all()
    variants = db.query(PostVariant).filter(PostVariant.post_id == post.id).all()
    media_links = db.query(PostMedia).filter(PostMedia.post_id == post.id).all()
    media_ids = [m.media_asset_id for m in media_links]

    return PostDetailResponse(
        id=post.id,
        workspace_id=post.workspace_id,
        title=post.title,
        content=post.content,
        content_type=post.content_type,
        status=post.status,
        category_id=post.category_id,
        scheduled_at=post.scheduled_at,
        published_at=post.published_at,
        created_at=post.created_at,
        updated_at=post.updated_at,
        targets=[PostTargetResponse.model_validate(t) for t in targets],
        variants=variants,
        media_asset_ids=media_ids,
    )


@router.put("/{post_id}", response_model=PostResponse)
@router.patch("/{post_id}", response_model=PostResponse)
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


@router.post("/{post_id}/duplicate", response_model=PostResponse, status_code=status.HTTP_201_CREATED)
def duplicate_post(
    post_id: str,
    member: WorkspaceMember = Depends(require_permission("posts.create")),
    db: Session = Depends(get_db),
):
    """Duplicate an existing post into a fresh draft copy."""
    service = PostService(db)
    post = service.get_post(post_id)
    if post.workspace_id != member.workspace_id:
        raise ForbiddenException("Cross-tenant duplication prohibited.")
    return service.duplicate_post(post_id, member.workspace_id)


# --- Publishing Actions ---

@router.post("/{post_id}/publish")
async def publish_post_immediately(
    post_id: str,
    member: WorkspaceMember = Depends(require_permission("posts.create")),
    db: Session = Depends(get_db),
):
    """Publish a post immediately to all target social accounts."""
    publisher = PublishingService(db)
    return await publisher.publish_post_now(post_id, member.workspace_id)


@router.post("/{post_id}/schedule", response_model=PostResponse)
def schedule_post(
    post_id: str,
    payload: SchedulePostRequest,
    member: WorkspaceMember = Depends(require_permission("posts.create")),
    db: Session = Depends(get_db),
):
    """Schedule post for future execution at a specified date and time in UTC."""
    scheduler = SchedulingService(db)
    return scheduler.schedule_post(
        post_id=post_id,
        scheduled_at=payload.scheduled_at,
        workspace_id=member.workspace_id,
        timezone_name=payload.timezone,
    )


@router.post("/{post_id}/cancel", response_model=PostResponse)
def cancel_scheduled_post(
    post_id: str,
    member: WorkspaceMember = Depends(require_permission("posts.update")),
    db: Session = Depends(get_db),
):
    """Cancel a scheduled post and return it to draft status."""
    scheduler = SchedulingService(db)
    return scheduler.cancel_scheduled_post(post_id, member.workspace_id)


@router.get("/{post_id}/publishing-status", response_model=PublishingStatusResponse)
def get_post_publishing_status(
    post_id: str,
    member: WorkspaceMember = Depends(require_permission("posts.view")),
    db: Session = Depends(get_db),
):
    """Get live publishing status of parent post and each target account."""
    service = PostService(db)
    post = service.get_post(post_id)
    if post.workspace_id != member.workspace_id:
        raise ForbiddenException("Cross-tenant access prohibited.")

    targets = db.query(PostTarget).filter(PostTarget.post_id == post.id).all()
    target_list = []
    for t in targets:
        account = db.query(SocialAccount).filter(SocialAccount.id == t.social_account_id).first()
        target_list.append({
            "target_id": t.id,
            "social_account_id": t.social_account_id,
            "platform": account.platform if account else "unknown",
            "account_name": account.account_name if account else "Unknown Account",
            "status": t.status,
            "external_post_id": t.external_post_id,
            "error_message": t.error_message,
            "published_at": t.published_at.isoformat() if t.published_at else None,
        })

    return PublishingStatusResponse(
        post_id=post.id,
        status=post.status,
        scheduled_at=post.scheduled_at,
        published_at=post.published_at,
        targets=target_list,
    )


# --- Publishing Targets ---

@router.get("/{post_id}/targets", response_model=List[PostTargetResponse])
def list_post_targets(
    post_id: str,
    member: WorkspaceMember = Depends(require_permission("posts.view")),
    db: Session = Depends(get_db),
):
    """List all target accounts configured for this post."""
    service = PostService(db)
    post = service.get_post(post_id)
    if post.workspace_id != member.workspace_id:
        raise ForbiddenException("Cross-tenant access prohibited.")
    return db.query(PostTarget).filter(PostTarget.post_id == post.id).all()


@router.post("/{post_id}/targets/{target_id}/retry")
async def retry_single_target(
    post_id: str,
    target_id: str,
    member: WorkspaceMember = Depends(require_permission("posts.create")),
    db: Session = Depends(get_db),
):
    """Retry publishing an individual failed target account."""
    publisher = PublishingService(db)
    return await publisher.retry_failed_target(post_id, target_id, member.workspace_id)
