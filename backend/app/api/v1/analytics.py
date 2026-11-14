from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.schemas.analytics import AnalyticsOverviewResponse, PlatformAnalyticsResponse
from app.services.analytics_service import AnalyticsService

router = APIRouter(prefix="/analytics", tags=["Analytics"])


@router.get("/overview", response_model=AnalyticsOverviewResponse)
def get_analytics_overview(
    workspace_id: str = Query(..., description="Workspace ID"),
    db: Session = Depends(get_db),
):
    """Get high-level aggregated KPI metrics and 7-day timeline."""
    service = AnalyticsService(db)
    return service.get_overview(workspace_id)


@router.get("/platforms", response_model=PlatformAnalyticsResponse)
def get_platform_analytics(
    workspace_id: str = Query(..., description="Workspace ID"),
    db: Session = Depends(get_db),
):
    """Get per-platform performance metrics."""
    service = AnalyticsService(db)
    return service.get_platform_analytics(workspace_id)

