import asyncio
import logging
import signal
import sys
from typing import Optional

from app.analytics.services.sync_service import AnalyticsSyncService
from app.core.database import SessionLocal
from app.models.workspace import Workspace

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(name)s: %(message)s")
logger = logging.getLogger("AnalyticsSyncWorker")


class AnalyticsSyncWorker:
    """Production background worker for periodically synchronizing social platform analytics."""

    def __init__(self, check_interval_seconds: int = 3600):
        self.check_interval = check_interval_seconds
        self._running = False

    def sync_all_workspaces_once(self) -> int:
        """Run single synchronization cycle across all active workspaces."""
        db = SessionLocal()
        total_synced = 0
        try:
            sync_service = AnalyticsSyncService(db)
            workspaces = db.query(Workspace).all()

            for ws in workspaces:
                res = sync_service.sync_workspace(ws.id)
                total_synced += res.get("synced_accounts", 0)

            logger.info("AnalyticsSyncWorker cycle completed. Synced accounts: %d across %d workspaces", total_synced, len(workspaces))
        except Exception as e:
            logger.exception("Error in AnalyticsSyncWorker cycle: %s", e)
        finally:
            db.close()

        return total_synced

    async def run(self):
        """Main daemon loop."""
        self._running = True
        logger.info("Starting AnalyticsSyncWorker daemon (interval: %d s)...", self.check_interval)

        while self._running:
            try:
                self.sync_all_workspaces_once()
            except Exception as e:
                logger.exception("Unexpected error in worker loop: %s", e)

            try:
                await asyncio.sleep(self.check_interval)
            except asyncio.CancelledError:
                break

        logger.info("AnalyticsSyncWorker daemon stopped.")

    def stop(self):
        self._running = False


def main():
    worker = AnalyticsSyncWorker(check_interval_seconds=3600)

    loop = asyncio.new_event_loop()
    asyncio.set_event_loop(loop)

    def _handle_shutdown():
        logger.info("Received shutdown signal. Stopping AnalyticsSyncWorker...")
        worker.stop()
        for task in asyncio.all_tasks(loop):
            task.cancel()

    for sig in (signal.SIGINT, signal.SIGTERM):
        try:
            loop.add_signal_handler(sig, _handle_shutdown)
        except NotImplementedError:
            pass  # Windows event loop limitation

    try:
        loop.run_until_complete(worker.run())
    except (KeyboardInterrupt, SystemExit):
        logger.info("Worker interrupted by user.")
    finally:
        loop.close()
        logger.info("AnalyticsSyncWorker shutdown complete.")


if __name__ == "__main__":
    main()

