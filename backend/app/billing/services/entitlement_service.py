from datetime import datetime, timezone
from typing import Any, Dict
from sqlalchemy import func
from sqlalchemy.orm import Session

from app.billing.services.plan_service import PlanService
from app.core.exceptions import ForbiddenException
from app.models.billing import UsageRecord, WorkspaceSubscription
from app.models.media import MediaAsset
from app.models.membership import WorkspaceMember
from app.models.post import PostTarget
from app.models.social_account import SocialAccount


class EntitlementService:
    """Evaluates and enforces real-time workspace resource quotas and feature entitlements."""

    def __init__(self, db: Session):
        self.db = db
        self.plan_service = PlanService(db)

    def get_active_subscription(self, workspace_id: str) -> WorkspaceSubscription:
        """Fetch active subscription or default to active free plan."""
        sub = (
            self.db.query(WorkspaceSubscription)
            .filter(WorkspaceSubscription.workspace_id == workspace_id)
            .first()
        )
        if not sub:
            free_plan = self.plan_service.get_plan_by_code("free")
            now = datetime.now(timezone.utc)
            sub = WorkspaceSubscription(
                workspace_id=workspace_id,
                plan_id=free_plan.id,
                status="active",
                billing_cycle="monthly",
                current_period_start=now,
                current_period_end=datetime(now.year + 10, 1, 1, tzinfo=timezone.utc),
            )
            self.db.add(sub)
            self.db.commit()
            self.db.refresh(sub)
        return sub

    def get_workspace_usage_and_limits(self, workspace_id: str) -> Dict[str, Any]:
        """Aggregate truthful usage vs entitlement limits strictly for workspace."""
        sub = self.get_active_subscription(workspace_id)
        plan = sub.plan or self.plan_service.get_plan_by_id(sub.plan_id)

        # 1. Connected Social Accounts
        connected_accounts = (
            self.db.query(SocialAccount)
            .filter(
                SocialAccount.workspace_id == workspace_id,
                SocialAccount.connection_status == "connected",
            )
            .count()
        )

        # 2. Team Members
        team_members = (
            self.db.query(WorkspaceMember)
            .filter(
                WorkspaceMember.workspace_id == workspace_id,
                WorkspaceMember.status == "active",
            )
            .count()
        )

        # 3. Monthly Publishing Targets (within current billing cycle)
        period_start = sub.current_period_start or datetime.now(timezone.utc)
        monthly_published = (
            self.db.query(PostTarget)
            .join(SocialAccount, PostTarget.social_account_id == SocialAccount.id)
            .filter(
                SocialAccount.workspace_id == workspace_id,
                PostTarget.status == "published",
                PostTarget.updated_at >= period_start,
            )
            .count()
        )

        # 4. Storage Consumption (MB)
        total_bytes = (
            self.db.query(func.coalesce(func.sum(MediaAsset.file_size_bytes), 0))
            .filter(MediaAsset.workspace_id == workspace_id)
            .scalar()
        ) or 0
        storage_mb = round(total_bytes / (1024 * 1024), 1)

        return {
            "workspace_id": workspace_id,
            "plan_code": plan.plan_code,
            "plan_name": plan.name,
            "status": sub.status,
            "billing_cycle": sub.billing_cycle,
            "current_period_start": sub.current_period_start.isoformat() if sub.current_period_start else None,
            "current_period_end": sub.current_period_end.isoformat() if sub.current_period_end else None,
            "cancel_at_period_end": sub.cancel_at_period_end,
            "usage": {
                "connected_accounts": connected_accounts,
                "team_members": team_members,
                "monthly_publishing": monthly_published,
                "storage_mb": storage_mb,
            },
            "limits": {
                "max_social_accounts": plan.max_social_accounts,
                "max_team_members": plan.max_team_members,
                "monthly_published_targets": plan.monthly_published_targets,
                "max_storage_mb": plan.max_storage_mb,
                "analytics_history_days": plan.analytics_history_days,
                "export_enabled": plan.export_enabled,
            },
        }

    def assert_can_connect_account(self, workspace_id: str):
        """Guard: verify connected account quota before adding social account."""
        data = self.get_workspace_usage_and_limits(workspace_id)
        if data["usage"]["connected_accounts"] >= data["limits"]["max_social_accounts"]:
            raise ForbiddenException(
                f"Social account limit reached ({data['limits']['max_social_accounts']}). "
                f"Please upgrade your plan to connect more accounts."
            )

    def assert_can_publish_targets(self, workspace_id: str, new_target_count: int = 1):
        """Guard: verify monthly publishing quota before launching post targets."""
        data = self.get_workspace_usage_and_limits(workspace_id)
        current = data["usage"]["monthly_publishing"]
        limit = data["limits"]["monthly_published_targets"]
        if current + new_target_count > limit:
            raise ForbiddenException(
                f"Monthly publishing target quota exceeded ({current}/{limit}). "
                f"Upgrade to a higher subscription plan to continue publishing."
            )

    def assert_can_invite_member(self, workspace_id: str):
        """Guard: verify team member quota before sending invitations."""
        data = self.get_workspace_usage_and_limits(workspace_id)
        if data["usage"]["team_members"] >= data["limits"]["max_team_members"]:
            raise ForbiddenException(
                f"Team member limit reached ({data['limits']['max_team_members']}). "
                f"Upgrade your subscription plan to add more team collaborators."
            )

    def assert_can_export_reports(self, workspace_id: str):
        """Guard: verify report export entitlement."""
        data = self.get_workspace_usage_and_limits(workspace_id)
        if not data["limits"]["export_enabled"]:
            raise ForbiddenException(
                "Analytics report export is not available on the Free plan. "
                "Please upgrade to Starter, Professional, or Business to export CSV reports."
            )

