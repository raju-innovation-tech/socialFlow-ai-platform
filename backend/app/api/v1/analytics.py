from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.core.deps import require_permission
from app.models.membership import WorkspaceMember
from app.schemas.analytics import AnalyticsOverviewResponse, PlatformAnalyticsResponse
from app.services.analytics_service import AnalyticsService

router = APIRouter(prefix="/analytics", tags=["Analytics"])


@router.get("/overview", response_model=AnalyticsOverviewResponse)
def get_analytics_overview(
    member: WorkspaceMember = Depends(require_permission("analytics.view")),
    db: Session = Depends(get_db),
):
    """Get high-level aggregated KPI metrics strictly for the active workspace."""
    service = AnalyticsService(db)
    return service.get_overview(member.workspace_id)


@router.get("/platforms", response_model=PlatformAnalyticsResponse)
def get_platform_analytics(
    member: WorkspaceMember = Depends(require_permission("analytics.view")),
    db: Session = Depends(get_db),
):
    """Get per-platform performance metrics strictly for the active workspace."""
    service = AnalyticsService(db)
    return service.get_platform_analytics(member.workspace_id)
