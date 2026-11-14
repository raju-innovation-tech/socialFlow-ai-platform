import hashlib
import time
from datetime import datetime, timedelta, timezone
from typing import List, Optional
import zoneinfo
from sqlalchemy.orm import Session

from app.core.exceptions import BadRequestException, NotFoundException
from app.core.logging import logger
from app.models.post import Post, PostTarget
from app.models.publishing import PublishingJob


class SchedulingService:
    """Manages post scheduling, timezone normalization, rescheduling, cancellation, and due-job dispatch."""

    def __init__(self, db: Session):
        self.db = db

    def schedule_post(
        self,
        post_id: str,
        scheduled_at: datetime,
        workspace_id: str,
        timezone_name: str = "UTC",
    ) -> Post:
        """Schedule a post for future execution with UTC normalization."""
        post = self.db.query(Post).filter(Post.id == post_id, Post.workspace_id == workspace_id).first()
        if not post:
            raise NotFoundException("Post", post_id)

        # Enforce that post has at least one target
        target_count = self.db.query(PostTarget).filter(PostTarget.post_id == post.id).count()
        if target_count == 0:
            raise BadRequestException("Cannot schedule a post with no target social accounts selected.")

        # Normalize incoming datetime to UTC
        if scheduled_at.tzinfo is None:
            try:
                user_tz = zoneinfo.ZoneInfo(timezone_name)
                local_dt = scheduled_at.replace(tzinfo=user_tz)
                utc_dt = local_dt.astimezone(timezone.utc)
            except Exception:
                utc_dt = scheduled_at.replace(tzinfo=timezone.utc)
        else:
            utc_dt = scheduled_at.astimezone(timezone.utc)

        # Prevent scheduling in the past (minimum 30 seconds buffer)
        now_utc = datetime.now(timezone.utc)
        if utc_dt <= now_utc:
            raise BadRequestException("Scheduled time must be at least 1 minute in the future.")

        post.scheduled_at = utc_dt
        post.status = "scheduled"

        # Check if an existing pending job exists or create new
        existing_job = self.db.query(PublishingJob).filter(
            PublishingJob.post_id == post.id,
            PublishingJob.status.in_(["pending", "in_progress"]),
        ).first()

        idempotency_key = hashlib.sha256(f"sched_{post.id}_{int(utc_dt.timestamp())}".encode()).hexdigest()[:64]

        if existing_job:
            existing_job.scheduled_time = utc_dt
            existing_job.status = "pending"
            existing_job.idempotency_key = idempotency_key
        else:
            new_job = PublishingJob(
                post_id=post.id,
                scheduled_time=utc_dt,
                status="pending",
                idempotency_key=idempotency_key,
            )
            self.db.add(new_job)

        self.db.commit()
        self.db.refresh(post)
        logger.info("Post %s scheduled for %s UTC (workspace %s)", post.id, utc_dt.isoformat(), workspace_id)
        return post

    def reschedule_post(
        self,
        post_id: str,
        new_scheduled_at: datetime,
        workspace_id: str,
        timezone_name: str = "UTC",
    ) -> Post:
        """Reschedule an existing scheduled post."""
        return self.schedule_post(post_id, new_scheduled_at, workspace_id, timezone_name)

    def cancel_scheduled_post(self, post_id: str, workspace_id: str) -> Post:
        """Cancel a scheduled post and return its state to draft."""
        post = self.db.query(Post).filter(Post.id == post_id, Post.workspace_id == workspace_id).first()
        if not post:
            raise NotFoundException("Post", post_id)

        if post.status != "scheduled":
            raise BadRequestException(f"Cannot cancel a post with status '{post.status}'.")

        # Cancel any active publishing jobs
        jobs = self.db.query(PublishingJob).filter(
            PublishingJob.post_id == post.id,
            PublishingJob.status == "pending",
        ).all()
        for j in jobs:
            j.status = "cancelled"

        post.status = "draft"
        post.scheduled_at = None
        self.db.commit()
        self.db.refresh(post)
        logger.info("Post %s cancelled and reverted to draft (workspace %s)", post.id, workspace_id)
        return post

    def claim_due_jobs(self, limit: int = 20) -> List[PublishingJob]:
        """Atomically fetch and claim due scheduled jobs from PostgreSQL (source of truth)."""
        now_utc = datetime.now(timezone.utc)
        # Select pending jobs that are due
        due_jobs = (
            self.db.query(PublishingJob)
            .filter(
                PublishingJob.status == "pending",
                PublishingJob.scheduled_time <= now_utc,
            )
            .order_by(PublishingJob.scheduled_time.asc())
            .limit(limit)
            .with_for_update(skip_locked=True)
            .all()
        )

        for job in due_jobs:
            job.status = "in_progress"

        self.db.commit()
        return due_jobs

