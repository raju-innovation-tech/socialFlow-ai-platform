import logging
from datetime import date, datetime, timezone
from typing import Any, Dict, List
from sqlalchemy.orm import Session

from app.analytics.providers.analytics_registry import get_analytics_registry
from app.models.analytics import AnalyticsSnapshot, PostMetric
from app.models.post import Post, PostTarget
from app.models.social_account import SocialAccount

logger = logging.getLogger(__name__)


class AnalyticsSyncService:
    """Synchronizes truthful analytics metrics from social platform APIs into database snapshots."""

    def __init__(self, db: Session):
        self.db = db
        self.registry = get_analytics_registry()

    def sync_workspace(self, workspace_id: str) -> Dict[str, Any]:
        """Fetch latest truthful metrics for all connected accounts in a workspace."""
        accounts = (
            self.db.query(SocialAccount)
            .filter(
                SocialAccount.workspace_id == workspace_id,
                SocialAccount.connection_status == "connected",
            )
            .all()
        )

        today = date.today()
        synced_count = 0

        for account in accounts:
            try:
                provider = self.registry.get_provider(account.platform)
                if not provider:
                    logger.warning(f"No analytics provider for platform {account.platform}")
                    continue

                # 1. Fetch account-level metrics
                metrics = provider.fetch_account_metrics(account)

                # Update live account record if supported
                if metrics.follower_count is not None:
                    account.follower_count = metrics.follower_count
                account.last_sync_at = datetime.now(timezone.utc)

                # 2. Record daily AnalyticsSnapshot
                snapshot = (
                    self.db.query(AnalyticsSnapshot)
                    .filter(
                        AnalyticsSnapshot.account_id == account.id,
                        AnalyticsSnapshot.snapshot_date == today,
                    )
                    .first()
                )

                if not snapshot:
                    snapshot = AnalyticsSnapshot(
                        account_id=account.id,
                        snapshot_date=today,
                        followers_count=metrics.follower_count or 0,
                        impressions_count=metrics.impressions or 0,
                        reach_count=metrics.reach or 0,
                        engagement_rate=metrics.engagement_rate or 0.0,
                    )
                    self.db.add(snapshot)
                else:
                    snapshot.followers_count = metrics.follower_count or 0
                    snapshot.impressions_count = metrics.impressions or 0
                    snapshot.reach_count = metrics.reach or 0
                    snapshot.engagement_rate = metrics.engagement_rate or 0.0

                # 3. Sync post-level metrics for published targets
                targets = (
                    self.db.query(PostTarget)
                    .filter(
                        PostTarget.social_account_id == account.id,
                        PostTarget.status == "published",
                        PostTarget.external_post_id != None,
                    )
                    .limit(20)
                    .all()
                )

                for target in targets:
                    post_metrics = provider.fetch_post_metrics(account, target.external_post_id)
                    existing_pm = (
                        self.db.query(PostMetric)
                        .filter(
                            PostMetric.post_id == target.post_id,
                            PostMetric.social_account_id == account.id,
                        )
                        .first()
                    )
                    if not existing_pm:
                        new_pm = PostMetric(
                            post_id=target.post_id,
                            social_account_id=account.id,
                            recorded_at=datetime.now(timezone.utc),
                            impressions=post_metrics.impressions or 0,
                            reach=post_metrics.reach or 0,
                            likes=post_metrics.likes or 0,
                            comments=post_metrics.comments or 0,
                            shares=post_metrics.shares or 0,
                            clicks=post_metrics.clicks or 0,
                        )
                        self.db.add(new_pm)
                    else:
                        existing_pm.impressions = post_metrics.impressions or 0
                        existing_pm.reach = post_metrics.reach or 0
                        existing_pm.likes = post_metrics.likes or 0
                        existing_pm.comments = post_metrics.comments or 0
                        existing_pm.shares = post_metrics.shares or 0
                        existing_pm.clicks = post_metrics.clicks or 0
                        existing_pm.recorded_at = datetime.now(timezone.utc)

                synced_count += 1
            except Exception as e:
                logger.error(f"Error syncing account {account.id} ({account.platform}): {e}")

        self.db.commit()
        return {
            "workspace_id": workspace_id,
            "synced_accounts": synced_count,
            "status": "success",
            "message": f"Successfully synchronized {synced_count} account(s).",
        }

