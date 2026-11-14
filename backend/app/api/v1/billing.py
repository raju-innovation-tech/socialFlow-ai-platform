from datetime import datetime, timedelta, timezone
from decimal import Decimal
from typing import List
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.models.billing import SubscriptionPlan
from app.schemas.billing import SubscriptionPlanResponse, WorkspaceSubscriptionResponse

router = APIRouter(prefix="/billing", tags=["Billing"])


@router.get("/plans", response_model=List[SubscriptionPlanResponse])
def list_subscription_plans(db: Session = Depends(get_db)):
    """List available SaaS subscription tiers (Free, Pro, Enterprise)."""
    plans = db.query(SubscriptionPlan).filter(SubscriptionPlan.is_active == True).all()
    if not plans:
        # Fallback baseline plans if DB hasn't been seeded yet
        return [
            SubscriptionPlanResponse(
                id="plan_free",
                plan_code="free",
                name="Free Starter",
                price_monthly=Decimal("0.00"),
                price_annual=Decimal("0.00"),
                currency="USD",
                ai_credits_monthly=500,
                max_social_accounts=3,
                max_team_members=1,
                is_active=True,
            ),
            SubscriptionPlanResponse(
                id="plan_pro",
                plan_code="pro",
                name="Pro Growth",
                price_monthly=Decimal("49.00"),
                price_annual=Decimal("470.00"),
                currency="USD",
                ai_credits_monthly=5000,
                max_social_accounts=15,
                max_team_members=5,
                is_active=True,
            ),
            SubscriptionPlanResponse(
                id="plan_enterprise",
                plan_code="enterprise",
                name="Enterprise Scale",
                price_monthly=Decimal("199.00"),
                price_annual=Decimal("1900.00"),
                currency="USD",
                ai_credits_monthly=25000,
                max_social_accounts=50,
                max_team_members=25,
                is_active=True,
            ),
        ]
    return plans


@router.get("/subscription", response_model=WorkspaceSubscriptionResponse)
def get_workspace_subscription(
    workspace_id: str = Query(..., description="Workspace ID"),
    db: Session = Depends(get_db),
):
    """Get active subscription status for workspace (Mock foundation for Phase 2)."""
    now = datetime.now(timezone.utc)
    return WorkspaceSubscriptionResponse(
        id=f"sub_{workspace_id[:8]}",
        workspace_id=workspace_id,
        plan=SubscriptionPlanResponse(
            id="plan_pro",
            plan_code="pro",
            name="Pro Growth",
            price_monthly=Decimal("49.00"),
            price_annual=Decimal("470.00"),
            currency="USD",
            ai_credits_monthly=5000,
            max_social_accounts=15,
            max_team_members=5,
            is_active=True,
        ),
        status="active",
        current_period_start=now - timedelta(days=12),
        current_period_end=now + timedelta(days=18),
        cancel_at_period_end=False,
    )

