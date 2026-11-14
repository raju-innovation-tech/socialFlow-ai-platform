from datetime import datetime
from typing import Any, Dict, List, Optional
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.deps import require_permission
from app.models.membership import WorkspaceMember
from app.models.post import Post, PostTarget
from app.models.publishing import PublishingAttempt, PublishingJob
from app.models.social_account import SocialAccount

router = APIRouter(prefix="/publishing", tags=["Publishing Queue & Calendar"])


@router.get("/calendar")
def get_publishing_calendar(
    start_date: Optional[datetime] = Query(None, description="Start boundary (ISO timestamp)"),
    end_date: Optional[datetime] = Query(None, description="End boundary (ISO timestamp)"),
    member: WorkspaceMember = Depends(require_permission("posts.view")),
    db: Session = Depends(get_db),
) -> List[Dict[str, Any]]:
    """Retrieve scheduled and published calendar events formatted for daily/weekly/monthly visual timelines."""
    query = db.query(Post).filter(
        Post.workspace_id == member.workspace_id,
        Post.status.in_(["scheduled", "published", "publishing", "failed"]),
    )

    if start_date:
        query = query.filter(Post.scheduled_at >= start_date)
    if end_date:
        query = query.filter(Post.scheduled_at <= end_date)

    posts = query.order_by(Post.scheduled_at.asc()).all()
    events = []

    for p in posts:
        targets = db.query(PostTarget).filter(PostTarget.post_id == p.id).all()
        platforms = []
        for t in targets:
            acc = db.query(SocialAccount).filter(SocialAccount.id == t.social_account_id).first()
            if acc:
                platforms.append(acc.platform)

        events.append({
            "id": p.id,
            "title": p.title or (p.content[:40] + "..." if len(p.content) > 40 else p.content),
            "content": p.content,
            "status": p.status,
            "scheduled_at": p.scheduled_at.isoformat() if p.scheduled_at else None,
            "published_at": p.published_at.isoformat() if p.published_at else None,
            "platforms": list(set(platforms)),
            "targets_count": len(targets),
        })

    return events


@router.get("/queue")
def get_publishing_queue(
    member: WorkspaceMember = Depends(require_permission("posts.view")),
    db: Session = Depends(get_db),
) -> List[Dict[str, Any]]:
    """Retrieve active publishing queue including scheduled, queued, and in-progress jobs."""
    jobs = (
        db.query(PublishingJob)
        .join(Post, PublishingJob.post_id == Post.id)
        .filter(
            Post.workspace_id == member.workspace_id,
            PublishingJob.status.in_(["pending", "in_progress"]),
        )
        .order_by(PublishingJob.scheduled_time.asc())
        .all()
    )

    queue_items = []
    for j in jobs:
        post = j.post
        targets = db.query(PostTarget).filter(PostTarget.post_id == post.id).all()
        platforms = []
        for t in targets:
            acc = db.query(SocialAccount).filter(SocialAccount.id == t.social_account_id).first()
            if acc:
                platforms.append(acc.platform)

        queue_items.append({
            "job_id": j.id,
            "post_id": post.id,
            "title": post.title or post.content[:40],
            "status": j.status,
            "post_status": post.status,
            "scheduled_time": j.scheduled_time.isoformat(),
            "retry_count": j.retry_count,
            "max_retries": j.max_retries,
            "platforms": list(set(platforms)),
        })

    return queue_items


@router.get("/history")
def get_publishing_history(
    skip: int = 0,
    limit: int = 50,
    member: WorkspaceMember = Depends(require_permission("posts.view")),
    db: Session = Depends(get_db),
) -> List[Dict[str, Any]]:
    """Retrieve chronological audit history of completed and failed publishing executions."""
    attempts = (
        db.query(PublishingAttempt)
        .join(PublishingJob, PublishingAttempt.job_id == PublishingJob.id)
        .join(Post, PublishingJob.post_id == Post.id)
        .filter(Post.workspace_id == member.workspace_id)
        .order_by(PublishingAttempt.attempted_at.desc())
        .offset(skip)
        .limit(limit)
        .all()
    )

    history = []
    for a in attempts:
        job = a.job
        post = job.post if job else None
        history.append({
            "attempt_id": a.id,
            "job_id": a.job_id,
            "post_id": post.id if post else None,
            "post_title": post.title if post else "Unknown",
            "attempt_number": a.attempt_number,
            "attempted_at": a.attempted_at.isoformat(),
            "duration_ms": a.duration_ms,
            "status": a.status,
            "error_details": a.error_details,
        })

    return history


@router.get("/failed")
def get_failed_publishing_targets(
    member: WorkspaceMember = Depends(require_permission("posts.view")),
    db: Session = Depends(get_db),
) -> List[Dict[str, Any]]:
    """Retrieve failed publishing targets eligible for retry and manual reconciliation."""
    targets = (
        db.query(PostTarget)
        .join(Post, PostTarget.post_id == Post.id)
        .filter(
            Post.workspace_id == member.workspace_id,
            PostTarget.status == "failed",
        )
        .order_by(PostTarget.updated_at.desc())
        .all()
    )

    failed_list = []
    for t in targets:
        post = t.post
        acc = db.query(SocialAccount).filter(SocialAccount.id == t.social_account_id).first()
        failed_list.append({
            "target_id": t.id,
            "post_id": post.id,
            "post_title": post.title or post.content[:40],
            "social_account_id": t.social_account_id,
            "account_name": acc.account_name if acc else "Unknown",
            "platform": acc.platform if acc else "unknown",
            "error_message": t.error_message,
            "failed_at": t.updated_at.isoformat(),
        })

    return failed_list

