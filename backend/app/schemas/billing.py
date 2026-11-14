from datetime import datetime
from decimal import Decimal
from typing import Any, Dict, List, Optional
from pydantic import BaseModel, ConfigDict, Field


class SubscriptionPlanResponse(BaseModel):
    id: str
    plan_code: str
    name: str
    description: Optional[str] = None
    price_monthly: Decimal
    price_annual: Decimal
    currency: str
    trial_days: int = 0
    max_social_accounts: int = 3
    max_team_members: int = 1
    monthly_published_targets: int = 30
    max_storage_mb: int = 500
    analytics_history_days: int = 7
    export_enabled: bool = False
    is_active: bool = True
    is_public: bool = True
    display_order: int = 0

    model_config = ConfigDict(from_attributes=True)


class WorkspaceSubscriptionResponse(BaseModel):
    id: str
    workspace_id: str
    plan: SubscriptionPlanResponse
    status: str
    billing_cycle: str = "monthly"
    current_period_start: datetime
    current_period_end: datetime
    cancel_at_period_end: bool = False

    model_config = ConfigDict(from_attributes=True)


class CheckoutOrderRequest(BaseModel):
    plan_code: str = Field(..., example="pro")
    billing_cycle: str = Field("monthly", pattern="^(monthly|annual)$")


class CheckoutOrderResponse(BaseModel):
    free_tier: Optional[bool] = False
    order_id: Optional[str] = None
    amount: Optional[float] = None
    amount_subunits: Optional[int] = None
    currency: Optional[str] = "INR"
    key_id: Optional[str] = None
    plan_code: str
    plan_name: Optional[str] = None
    billing_cycle: str
    receipt: Optional[str] = None
    message: Optional[str] = None


class VerifyPaymentRequest(BaseModel):
    order_id: str
    payment_id: str
    signature: str
    plan_code: str
    billing_cycle: str = "monthly"


class VerifyPaymentResponse(BaseModel):
    status: str
    message: str
    subscription_id: str
    invoice_number: str


class QuotaUsageItem(BaseModel):
    connected_accounts: int
    team_members: int
    monthly_publishing: int
    storage_mb: float


class QuotaLimitsItem(BaseModel):
    max_social_accounts: int
    max_team_members: int
    monthly_published_targets: int
    max_storage_mb: int
    analytics_history_days: int
    export_enabled: bool


class WorkspaceUsageResponse(BaseModel):
    workspace_id: str
    plan_code: str
    plan_name: str
    status: str
    billing_cycle: str
    current_period_start: Optional[str] = None
    current_period_end: Optional[str] = None
    cancel_at_period_end: bool
    usage: QuotaUsageItem
    limits: QuotaLimitsItem


class InvoiceResponse(BaseModel):
    id: str
    workspace_id: str
    invoice_number: str
    subtotal_amount: Decimal
    tax_amount: Decimal
    amount_paid: Decimal
    currency: str
    status: str
    payment_method: str
    paid_at: Optional[datetime] = None
    invoice_url: Optional[str] = None

    model_config = ConfigDict(from_attributes=True)


class RefundRequest(BaseModel):
    invoice_id: str
    reason: Optional[str] = "Customer refund request"


class RefundResponse(BaseModel):
    status: str
    refund_id: str
    provider_refund_id: str
    amount: float
    currency: str
    message: str


class PlanCreateRequest(BaseModel):
    plan_code: str
    name: str
    description: Optional[str] = None
    price_monthly: Decimal
    price_annual: Decimal
    currency: str = "INR"
    trial_days: int = 0
    max_social_accounts: int = 5
    max_team_members: int = 2
    monthly_published_targets: int = 100
    max_storage_mb: int = 2000
    analytics_history_days: int = 30
    export_enabled: bool = True
    display_order: int = 5


class PlanUpdateRequest(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    price_monthly: Optional[Decimal] = None
    price_annual: Optional[Decimal] = None
    max_social_accounts: Optional[int] = None
    max_team_members: Optional[int] = None
    monthly_published_targets: Optional[int] = None
    max_storage_mb: Optional[int] = None
    export_enabled: Optional[bool] = None
    is_active: Optional[bool] = None
    is_public: Optional[bool] = None
