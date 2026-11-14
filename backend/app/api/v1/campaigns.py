from typing import List
from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.core.deps import require_permission
from app.core.exceptions import ForbiddenException
from app.models.membership import WorkspaceMember
from app.schemas.campaign import CampaignCreate, CampaignResponse, CampaignUpdate
from app.services.campaign_service import CampaignService

router = APIRouter(prefix="/campaigns", tags=["Campaigns"])


@router.get("", response_model=List[CampaignResponse])
def list_campaigns(
    skip: int = 0,
    limit: int = 50,
    member: WorkspaceMember = Depends(require_permission("campaigns.view")),
    db: Session = Depends(get_db),
):
    """List campaigns strictly scoped to the active workspace."""
    service = CampaignService(db)
    return service.list_campaigns(member.workspace_id, skip=skip, limit=limit)


@router.post("", response_model=CampaignResponse, status_code=status.HTTP_201_CREATED)
def create_campaign(
    payload: CampaignCreate,
    member: WorkspaceMember = Depends(require_permission("campaigns.create")),
    db: Session = Depends(get_db),
):
    """Create a new campaign in active workspace."""
    payload.workspace_id = member.workspace_id
    service = CampaignService(db)
    return service.create_campaign(payload)


@router.get("/{campaign_id}", response_model=CampaignResponse)
def get_campaign(
    campaign_id: str,
    member: WorkspaceMember = Depends(require_permission("campaigns.view")),
    db: Session = Depends(get_db),
):
    """Get single campaign details with tenant check."""
    service = CampaignService(db)
    campaign = service.get_campaign(campaign_id)
    if campaign.workspace_id != member.workspace_id:
        raise ForbiddenException("Cross-tenant access prohibited.")
    return campaign


@router.put("/{campaign_id}", response_model=CampaignResponse)
def update_campaign(
    campaign_id: str,
    payload: CampaignUpdate,
    member: WorkspaceMember = Depends(require_permission("campaigns.update")),
    db: Session = Depends(get_db),
):
    """Update campaign with tenant check."""
    service = CampaignService(db)
    campaign = service.get_campaign(campaign_id)
    if campaign.workspace_id != member.workspace_id:
        raise ForbiddenException("Cross-tenant mutation prohibited.")
    return service.update_campaign(campaign_id, payload)
