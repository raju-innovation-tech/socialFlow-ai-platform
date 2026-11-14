import json
from decimal import Decimal
from typing import Any, Dict, List, Optional
from sqlalchemy.orm import Session

from app.core.exceptions import BadRequestException, NotFoundException
from app.models.billing import SubscriptionPlan


INITIAL_PLANS = [
    {
        "plan_code": "free",
        "name": "Free Starter",
        "description": "Essential social media presence for individuals and creators.",
        "price_monthly": Decimal("0.00"),
        "price_annual": Decimal("0.00"),
        "currency": "INR",
        "trial_days": 0,
        "max_social_accounts": 3,
        "max_team_members": 1,
        "monthly_published_targets": 30,
        "max_storage_mb": 500,
        "analytics_history_days": 7,
        "export_enabled": False,
        "display_order": 1,
        "features_json": json.dumps({
            "social_accounts": 3,
            "monthly_publishing": 30,
            "team_members": 1,
            "analytics": "basic",
            "approvals": False,
            "priority_support": False,
        }),
    },
    {
        "plan_code": "starter",
        "name": "Starter Plan",
        "description": "Expanded publishing and audience analytics for growing brands.",
        "price_monthly": Decimal("999.00"),
        "price_annual": Decimal("9990.00"),
        "currency": "INR",
        "trial_days": 14,
        "max_social_accounts": 7,
        "max_team_members": 3,
        "monthly_published_targets": 150,
        "max_storage_mb": 5000,
        "analytics_history_days": 30,
        "export_enabled": True,
        "display_order": 2,
        "features_json": json.dumps({
            "social_accounts": 7,
            "monthly_publishing": 150,
            "team_members": 3,
            "analytics": "extended",
            "approvals": False,
            "priority_support": False,
        }),
    },
    {
        "plan_code": "pro",
        "name": "Professional Plan",
        "description": "Advanced multi-platform publishing, scheduling, and team collaboration.",
        "price_monthly": Decimal("2499.00"),
        "price_annual": Decimal("24990.00"),
        "currency": "INR",
        "trial_days": 14,
        "max_social_accounts": 15,
        "max_team_members": 5,
        "monthly_published_targets": 500,
        "max_storage_mb": 25000,
        "analytics_history_days": 90,
        "export_enabled": True,
        "display_order": 3,
        "features_json": json.dumps({
            "social_accounts": 15,
            "monthly_publishing": 500,
            "team_members": 5,
            "analytics": "advanced",
            "approvals": True,
            "priority_support": False,
        }),
    },
    {
        "plan_code": "business",
        "name": "Business Enterprise",
        "description": "High-volume multi-brand management with custom workflows and dedicated support.",
        "price_monthly": Decimal("6999.00"),
        "price_annual": Decimal("69990.00"),
        "currency": "INR",
        "trial_days": 30,
        "max_social_accounts": 50,
        "max_team_members": 20,
        "monthly_published_targets": 2500,
        "max_storage_mb": 100000,
        "analytics_history_days": 365,
        "export_enabled": True,
        "display_order": 4,
        "features_json": json.dumps({
            "social_accounts": 50,
            "monthly_publishing": 2500,
            "team_members": 20,
            "analytics": "full_suite",
            "approvals": True,
            "priority_support": True,
        }),
    },
]


class PlanService:
    def __init__(self, db: Session):
        self.db = db

    def list_public_plans(self) -> List[SubscriptionPlan]:
        """Fetch all public active subscription plans ordered by display_order."""
        self.ensure_default_plans_seeded()
        return (
            self.db.query(SubscriptionPlan)
            .filter(SubscriptionPlan.is_active == True, SubscriptionPlan.is_public == True)
            .order_by(SubscriptionPlan.display_order.asc())
            .all()
        )

    def get_plan_by_code(self, plan_code: str) -> SubscriptionPlan:
        """Fetch plan by unique plan_code."""
        plan = self.db.query(SubscriptionPlan).filter(SubscriptionPlan.plan_code == plan_code).first()
        if not plan:
            self.ensure_default_plans_seeded()
            plan = self.db.query(SubscriptionPlan).filter(SubscriptionPlan.plan_code == plan_code).first()
        if not plan:
            raise NotFoundException("SubscriptionPlan", plan_code)
        return plan

    def get_plan_by_id(self, plan_id: str) -> SubscriptionPlan:
        plan = self.db.query(SubscriptionPlan).filter(SubscriptionPlan.id == plan_id).first()
        if not plan:
            raise NotFoundException("SubscriptionPlan", plan_id)
        return plan

    def ensure_default_plans_seeded(self):
        """Seed default 4 plans if database table is empty."""
        count = self.db.query(SubscriptionPlan).count()
        if count == 0:
            for item in INITIAL_PLANS:
                p = SubscriptionPlan(
                    plan_code=item["plan_code"],
                    name=item["name"],
                    description=item["description"],
                    price_monthly=item["price_monthly"],
                    price_annual=item["price_annual"],
                    currency=item["currency"],
                    trial_days=item["trial_days"],
                    max_social_accounts=item["max_social_accounts"],
                    max_team_members=item["max_team_members"],
                    monthly_published_targets=item["monthly_published_targets"],
                    max_storage_mb=item["max_storage_mb"],
                    analytics_history_days=item["analytics_history_days"],
                    export_enabled=item["export_enabled"],
                    display_order=item["display_order"],
                    features_json=item["features_json"],
                    is_active=True,
                    is_public=True,
                )
                self.db.add(p)
            self.db.commit()

    def create_plan(self, data: Dict[str, Any]) -> SubscriptionPlan:
        """Super Admin: create a new custom subscription plan."""
        existing = self.db.query(SubscriptionPlan).filter(SubscriptionPlan.plan_code == data["plan_code"]).first()
        if existing:
            raise BadRequestException(f"Plan code '{data['plan_code']}' already exists.")

        plan = SubscriptionPlan(**data)
        self.db.add(plan)
        self.db.commit()
        self.db.refresh(plan)
        return plan

    def update_plan(self, plan_id: str, updates: Dict[str, Any]) -> SubscriptionPlan:
        """Super Admin: update an existing subscription plan."""
        plan = self.get_plan_by_id(plan_id)
        for k, v in updates.items():
            if hasattr(plan, k) and v is not None:
                setattr(plan, k, v)
        self.db.commit()
        self.db.refresh(plan)
        return plan

