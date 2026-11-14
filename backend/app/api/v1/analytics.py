from fastapi import APIRouter, Depends, Query, Response
from sqlalchemy.orm import Session

from app.analytics.services.analytics_service import AnalyticsService
from app.analytics.services.sync_service import AnalyticsSyncService
from app.core.database import get_db
from app.core.deps import require_permission
from app.models.membership import WorkspaceMember
from app.schemas.analytics import (
    AccountAnalyticsResponse,
    AnalyticsOverviewResponse,
    AnalyticsSyncResponse,
    PlatformAnalyticsResponse,
    PostAnalyticsResponse,
)

router = APIRouter(prefix="/analytics", tags=["Analytics"])


@router.get("/overview", response_model=AnalyticsOverviewResponse)
def get_analytics_overview(
    period: str = Query("last_7_days", regex="^(today|last_7_days|last_30_days|last_90_days)$"),
    member: WorkspaceMember = Depends(require_permission("analytics.view")),
    db: Session = Depends(get_db),
):
    """Get high-level aggregated truthful KPI metrics strictly for the active workspace."""
    service = AnalyticsService(db)
    return service.get_overview(member.workspace_id, period=period)


@router.get("/platforms", response_model=PlatformAnalyticsResponse)
def get_platform_analytics(
    member: WorkspaceMember = Depends(require_permission("analytics.view")),
    db: Session = Depends(get_db),
):
    """Get per-platform performance metrics strictly for the active workspace."""
    service = AnalyticsService(db)
    return service.get_platform_analytics(member.workspace_id)


@router.get("/accounts/{account_id}", response_model=AccountAnalyticsResponse)
def get_account_analytics(
    account_id: str,
    member: WorkspaceMember = Depends(require_permission("analytics.view")),
    db: Session = Depends(get_db),
):
    """Get historical analytics snapshots and details for a connected account."""
    service = AnalyticsService(db)
    return service.get_account_analytics(account_id, member.workspace_id)


@router.get("/posts/{post_id}", response_model=PostAnalyticsResponse)
def get_post_analytics(
    post_id: str,
    member: WorkspaceMember = Depends(require_permission("analytics.view")),
    db: Session = Depends(get_db),
):
    """Get performance metrics for an individual published post across platform targets."""
    service = AnalyticsService(db)
    return service.get_post_analytics(post_id, member.workspace_id)


@router.post("/sync", response_model=AnalyticsSyncResponse)
def sync_analytics(
    member: WorkspaceMember = Depends(require_permission("analytics.manage")),
    db: Session = Depends(get_db),
):
    """Manually trigger metrics synchronization from connected social platform APIs."""
    sync_service = AnalyticsSyncService(db)
    res = sync_service.sync_workspace(member.workspace_id)
    return res


@router.post("/reports/export")
def export_analytics_report(
    member: WorkspaceMember = Depends(require_permission("analytics.export")),
    db: Session = Depends(get_db),
):
    """Export workspace analytics data to downloadable CSV report."""
    service = AnalyticsService(db)
    csv_data = service.export_report_csv(member.workspace_id)

    return Response(
        content=csv_data,
        media_type="text/csv",
        headers={
            "Content-Disposition": "attachment; filename=socialflow_analytics_report.csv",
        },
    )
