from typing import List
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.schemas.campaign import CampaignCreate, CampaignResponse, CampaignUpdate
from app.services.campaign_service import CampaignService

router = APIRouter(prefix="/campaigns", tags=["Campaigns"])


@router.get("", response_model=List[CampaignResponse])
def list_campaigns(
    workspace_id: str = Query(..., description="Workspace ID"),
    skip: int = 0,
    limit: int = 50,
    db: Session = Depends(get_db),
):
    """List campaigns for a workspace."""
    service = CampaignService(db)
    return service.list_campaigns(workspace_id, skip=skip, limit=limit)


@router.post("", response_model=CampaignResponse, status_code=status.HTTP_201_CREATED)
def create_campaign(payload: CampaignCreate, db: Session = Depends(get_db)):
    """Create a new campaign."""
    service = CampaignService(db)
    return service.create_campaign(payload)


@router.get("/{campaign_id}", response_model=CampaignResponse)
def get_campaign(campaign_id: str, db: Session = Depends(get_db)):
    """Get single campaign details."""
    service = CampaignService(db)
    return service.get_campaign(campaign_id)


@router.put("/{campaign_id}", response_model=CampaignResponse)
def update_campaign(campaign_id: str, payload: CampaignUpdate, db: Session = Depends(get_db)):
    """Update campaign details."""
    service = CampaignService(db)
    return service.update_campaign(campaign_id, payload)

