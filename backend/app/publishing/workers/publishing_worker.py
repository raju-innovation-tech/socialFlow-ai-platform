import asyncio
import signal
import sys
from datetime import datetime, timezone
from typing import Optional

from app.core.database import SessionLocal
from app.core.logging import logger, setup_logging
from app.models.post import Post
from app.models.publishing import PublishingJob
from app.publishing.services.publishing_service import PublishingService
from app.publishing.services.retry_service import RetryService
from app.publishing.services.scheduling_service import SchedulingService


class PublishingWorker:
    """Production background worker for executing scheduled posts and recovering due jobs."""

    def __init__(self, check_interval_seconds: int = 5):
        self.check_interval = check_interval_seconds
        self._running = False

    async def process_due_jobs_once(self) -> int:
        """Single polling cycle: claims due jobs from PostgreSQL and executes publishing."""
        db = SessionLocal()
        processed_count = 0

        try:
            scheduler = SchedulingService(db)
            due_jobs = scheduler.claim_due_jobs(limit=10)

            for job in due_jobs:
                post = db.query(Post).filter(Post.id == job.post_id).first()
                if not post:
                    job.status = "failed"
                    job.last_error = "Post not found"
                    db.commit()
                    continue

                logger.info("Worker executing scheduled post %s (job %s)", post.id, job.id)
                publisher = PublishingService(db)

                try:
                    result = await publisher.publish_post_now(post.id, post.workspace_id)
                    processed_count += 1
                    logger.info("Worker completed post %s with status %s", post.id, result["overall_status"])

                except Exception as e:
                    logger.exception("Worker failure publishing post %s: %s", post.id, e)
                    job.retry_count += 1
                    job.last_error = str(e)

                    if RetryService.is_eligible_for_retry(job.retry_count, job.max_retries):
                        job.status = "pending"
                        job.scheduled_time = RetryService.calculate_next_retry(job.retry_count)
                        logger.info("Rescheduled failed job %s for retry %d at %s", job.id, job.retry_count, job.scheduled_time)
                    else:
                        job.status = "failed"
                        post.status = "failed"

                    db.commit()

        except Exception as err:
            logger.error("Error in worker polling cycle: %s", err)
        finally:
            db.close()

        return processed_count

    async def start(self, stop_event: Optional[asyncio.Event] = None):
        """Start worker loop with graceful shutdown support."""
        self._running = True
        logger.info("PublishingWorker started (interval: %ds)", self.check_interval)

        while self._running:
            if stop_event and stop_event.is_set():
                break

            try:
                await self.process_due_jobs_once()
            except Exception as e:
                logger.error("Unexpected worker exception: %s", e)

            try:
                await asyncio.sleep(self.check_interval)
            except asyncio.CancelledError:
                break

        logger.info("PublishingWorker stopped gracefully.")

    def stop(self):
        self._running = False


async def run_standalone_worker():
    """Entry point for running worker as a standalone daemon."""
    setup_logging()
    worker = PublishingWorker(check_interval_seconds=5)
    logger.info("PublishingWorker daemon booted successfully. Polling for due scheduled posts every 5s...")
    loop = asyncio.get_running_loop()
    stop_event = asyncio.Event()

    for sig in (signal.SIGINT, signal.SIGTERM):
        try:
            loop.add_signal_handler(sig, lambda: stop_event.set())
        except NotImplementedError:
            pass  # Windows does not support add_signal_handler for all signals

    await worker.start(stop_event=stop_event)


if __name__ == "__main__":
    asyncio.run(run_standalone_worker())

