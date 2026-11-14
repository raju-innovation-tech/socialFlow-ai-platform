from datetime import datetime
from decimal import Decimal
from pydantic import BaseModel, ConfigDict


class SubscriptionPlanResponse(BaseModel):
    id: str
    plan_code: str
    name: str
    price_monthly: Decimal
    price_annual: Decimal
    currency: str
    ai_credits_monthly: int
    max_social_accounts: int
    max_team_members: int
    is_active: bool

    model_config = ConfigDict(from_attributes=True)


class WorkspaceSubscriptionResponse(BaseModel):
    id: str
    workspace_id: str
    plan: SubscriptionPlanResponse
    status: str
    current_period_start: datetime
    current_period_end: datetime
    cancel_at_period_end: bool

    model_config = ConfigDict(from_attributes=True)

