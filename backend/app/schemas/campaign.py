from datetime import datetime
from decimal import Decimal
from typing import List, Optional
from pydantic import BaseModel, Field, ConfigDict


class CampaignBase(BaseModel):
    name: str = Field(..., min_length=1, max_length=255)
    description: Optional[str] = None
    start_date: Optional[datetime] = None
    end_date: Optional[datetime] = None
    budget_amount: Optional[Decimal] = None
    budget_currency: str = "USD"


class CampaignCreate(CampaignBase):
    workspace_id: str
    post_ids: Optional[List[str]] = Field(default_factory=list)


class CampaignUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    status: Optional[str] = None
    start_date: Optional[datetime] = None
    end_date: Optional[datetime] = None
    budget_amount: Optional[Decimal] = None


class CampaignResponse(CampaignBase):
    id: str
    workspace_id: str
    status: str
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)

