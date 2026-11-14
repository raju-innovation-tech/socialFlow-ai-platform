import hashlib
import json
import time
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional
from sqlalchemy.orm import Session

from app.core.exceptions import BadRequestException, NotFoundException
from app.core.logging import logger
from app.core.redis import redis_service
from app.integrations.base.token_manager import TokenManager
from app.models.media import MediaAsset
from app.models.post import Post, PostMedia, PostTarget, PostVariant
from app.models.publishing import PublishingAttempt, PublishingJob
from app.models.social_account import SocialAccount
from app.publishing.adapters.adapter_registry import publishing_registry
from app.publishing.adapters.base import PublishingResult
from app.publishing.services.retry_service import RetryService


class PublishingService:
    """Orchestrates multi-platform publishing, idempotency, per-target execution, and audit logging."""

    def __init__(self, db: Session):
        self.db = db

    def _acquire_publishing_lock(self, post_id: str, target_id: str, ttl_seconds: int = 120) -> bool:
        """Acquire a temporary distributed lock via Redis to avoid concurrent double-publishing."""
        lock_key = f"lock:pub:{post_id}:{target_id}"
        try:
            # Check if lock already exists
            if redis_service.get(lock_key):
                return False
            return redis_service.set(lock_key, "locked", ex=ttl_seconds)
        except Exception as e:
            logger.warning("Redis lock error (proceeding with DB guard): %s", e)
            return True

    def _release_publishing_lock(self, post_id: str, target_id: str):
        try:
            redis_service.delete(f"lock:pub:{post_id}:{target_id}")
        except Exception:
            pass

    async def publish_target(
        self,
        post: Post,
        target: PostTarget,
        media_items: List[MediaAsset],
        variant_content: Optional[str] = None,
        job: Optional[PublishingJob] = None,
    ) -> PublishingResult:
        """Execute publishing for a single target social account with full lifecycle tracking."""
        account = self.db.query(SocialAccount).filter(SocialAccount.id == target.social_account_id).first()
        if not account:
            target.status = "failed"
            target.error_message = "Target social account not found in database."
            self.db.commit()
            return PublishingResult(success=False, error_code="ACCOUNT_NOT_FOUND", error_message=target.error_message)

        adapter = publishing_registry.get(account.platform)
        if not adapter:
            target.status = "failed"
            target.error_message = f"Publishing adapter for platform '{account.platform}' is unavailable."
            self.db.commit()
            return PublishingResult(success=False, error_code="ADAPTER_UNAVAILABLE", error_message=target.error_message)

        # Retrieve decrypted access token
        access_token, _, token_secret = TokenManager.get_decrypted_tokens(self.db, account.id)
        if not access_token:
            target.status = "failed"
            target.error_message = f"Missing decrypted credentials for account {account.account_name}."
            self.db.commit()
            return PublishingResult(success=False, error_code="MISSING_CREDENTIALS", error_message=target.error_message)

        # Acquire lock to prevent double publishing
        if not self._acquire_publishing_lock(post.id, target.id):
            return PublishingResult(
                success=False,
                error_code="CONCURRENT_PUBLISHING_BLOCKED",
                error_message="Another process is currently publishing to this target.",
                is_retryable=False,
            )

        target.status = "publishing"
        self.db.commit()

        content = variant_content or post.content
        start_time = time.time()

        try:
            extra_params = {}
            if account.platform == "telegram" and account.platform_account_id:
                extra_params["chat_id"] = account.platform_account_id
            if token_secret:
                extra_params["token_secret"] = token_secret

            result = await adapter.publish(
                account=account,
                decrypted_token=access_token,
                text=content,
                media_items=media_items,
                extra_params=extra_params,
            )

            duration_ms = int((time.time() - start_time) * 1000)

            # Record attempt in publishing_attempts
            if job:
                attempt = PublishingAttempt(
                    job_id=job.id,
                    attempt_number=job.retry_count + 1,
                    attempted_at=datetime.now(timezone.utc),
                    duration_ms=duration_ms,
                    status="success" if result.success else "failure",
                    response_payload=json.dumps(result.raw_response)[:10000] if result.raw_response else None,
                    error_details=result.error_message,
                )
                self.db.add(attempt)

            if result.success:
                target.status = "published"
                target.external_post_id = result.external_post_id
                target.published_at = datetime.now(timezone.utc)
                target.error_message = None
            else:
                target.status = "failed"
                target.error_message = result.error_message

            self.db.commit()
            return result

        except Exception as e:
            logger.exception("Unexpected error publishing to target %s: %s", target.id, e)
            target.status = "failed"
            target.error_message = str(e)
            self.db.commit()
            return PublishingResult(success=False, error_code="UNEXPECTED_ERROR", error_message=str(e), is_retryable=True)

        finally:
            self._release_publishing_lock(post.id, target.id)

    async def publish_post_now(self, post_id: str, workspace_id: str) -> Dict[str, Any]:
        """Publish all targets of a post immediately."""
        post = self.db.query(Post).filter(Post.id == post_id, Post.workspace_id == workspace_id).first()
        if not post:
            raise NotFoundException("Post", post_id)

        # Enforce RBAC/Approval status
        if post.status == "pending_approval":
            raise BadRequestException("Post requires approval before publishing.")

        targets = self.db.query(PostTarget).filter(PostTarget.post_id == post.id).all()
        if not targets:
            raise BadRequestException("Cannot publish post without at least one selected target account.")

        # Load variants and media items
        variants = {v.platform: v.customized_content for v in post.variants}
        media_links = self.db.query(PostMedia).filter(PostMedia.post_id == post.id).order_by(PostMedia.display_order).all()
        media_assets = [ml.media_asset for ml in media_links if ml.media_asset]

        # Generate idempotency key for this publishing batch
        idempotency_key = hashlib.sha256(f"{post.id}_{int(time.time())}".encode()).hexdigest()[:64]
        job = PublishingJob(
            post_id=post.id,
            scheduled_time=datetime.now(timezone.utc),
            status="in_progress",
            idempotency_key=idempotency_key,
        )
        self.db.add(job)
        post.status = "publishing"
        self.db.commit()

        results = {}
        success_count = 0
        failure_count = 0

        for target in targets:
            account = self.db.query(SocialAccount).filter(SocialAccount.id == target.social_account_id).first()
            platform_key = account.platform if account else "unknown"
            variant_content = variants.get(platform_key, post.content)

            res = await self.publish_target(
                post=post,
                target=target,
                media_items=media_assets,
                variant_content=variant_content,
                job=job,
            )

            results[target.id] = {
                "platform": platform_key,
                "account_name": account.account_name if account else "Unknown",
                "success": res.success,
                "external_post_id": res.external_post_id,
                "external_post_url": res.external_post_url,
                "error_message": res.error_message,
                "is_retryable": res.is_retryable,
            }

            if res.success:
                success_count += 1
            else:
                failure_count += 1

        # Determine overall post status
        if failure_count == 0:
            post.status = "published"
            post.published_at = datetime.now(timezone.utc)
            job.status = "completed"
        elif success_count > 0:
            post.status = "partially_published"
            post.published_at = datetime.now(timezone.utc)
            job.status = "completed"
        else:
            post.status = "failed"
            job.status = "failed"

        self.db.commit()

        # Phase 6: Multi-channel event notification dispatch
        try:
            from app.notifications.services.notification_service import NotificationService
            notif_service = NotificationService(self.db)
            recipient_user_id = post.created_by_user_id or "system"
            if post.status in ("published", "partially_published"):
                platforms_str = ", ".join(r.get("platform", "") for r in results if r.get("success"))
                notif_service.notify_post_published(
                    workspace_id=post.workspace_id,
                    user_id=recipient_user_id,
                    post_title=post.title or "Untitled Post",
                    platform=platforms_str or "social platforms",
                )
            elif post.status == "failed":
                notif_service.create_notification(
                    workspace_id=post.workspace_id,
                    user_id=recipient_user_id,
                    title="Publishing failed",
                    message=f'Failed to publish post "{post.title or "Untitled Post"}". Please review targets for details.',
                    notification_type="publishing",
                    metadata={"status": "failed", "post_id": post.id},
                )
        except Exception as notif_err:
            logger.warning("Failed to dispatch publishing event notification: %s", notif_err)

        return {
            "post_id": post.id,
            "overall_status": post.status,
            "success_count": success_count,
            "failure_count": failure_count,
            "targets": results,
            "job_id": job.id,
        }

    async def retry_failed_target(self, post_id: str, target_id: str, workspace_id: str) -> Dict[str, Any]:
        """Manually retry publishing an eligible failed target."""
        post = self.db.query(Post).filter(Post.id == post_id, Post.workspace_id == workspace_id).first()
        if not post:
            raise NotFoundException("Post", post_id)

        target = self.db.query(PostTarget).filter(PostTarget.id == target_id, PostTarget.post_id == post.id).first()
        if not target:
            raise NotFoundException("PostTarget", target_id)

        media_links = self.db.query(PostMedia).filter(PostMedia.post_id == post.id).order_by(PostMedia.display_order).all()
        media_assets = [ml.media_asset for ml in media_links if ml.media_asset]

        account = self.db.query(SocialAccount).filter(SocialAccount.id == target.social_account_id).first()
        platform_key = account.platform if account else "unknown"

        variant = self.db.query(PostVariant).filter(
            PostVariant.post_id == post.id, PostVariant.platform == platform_key
        ).first()
        content = variant.customized_content if variant else post.content

        # Locate existing or create new publishing job for this retry
        job = self.db.query(PublishingJob).filter(PublishingJob.post_id == post.id).order_by(PublishingJob.created_at.desc()).first()
        if not job:
            job = PublishingJob(
                post_id=post.id,
                scheduled_time=datetime.now(timezone.utc),
                status="in_progress",
                idempotency_key=hashlib.sha256(f"{target.id}_{int(time.time())}".encode()).hexdigest()[:64],
            )
            self.db.add(job)
            self.db.flush()

        res = await self.publish_target(
            post=post,
            target=target,
            media_items=media_assets,
            variant_content=content,
            job=job,
        )

        # Re-evaluate parent post status
        all_targets = self.db.query(PostTarget).filter(PostTarget.post_id == post.id).all()
        if all(t.status == "published" for t in all_targets):
            post.status = "published"
        elif any(t.status == "published" for t in all_targets):
            post.status = "partially_published"
        else:
            post.status = "failed"

        self.db.commit()

        return {
            "target_id": target.id,
            "platform": platform_key,
            "success": res.success,
            "external_post_id": res.external_post_id,
            "external_post_url": res.external_post_url,
            "error_message": res.error_message,
            "post_status": post.status,
        }

