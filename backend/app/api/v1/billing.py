from typing import List
from fastapi import APIRouter, Depends, Query, Response, status
from sqlalchemy.orm import Session

from app.billing.services.entitlement_service import EntitlementService
from app.billing.services.invoice_service import InvoiceService
from app.billing.services.plan_service import PlanService
from app.billing.services.subscription_service import SubscriptionService
from app.core.database import get_db
from app.core.deps import get_active_workspace_member, require_permission
from app.models.membership import WorkspaceMember
from app.schemas.billing import (
    CheckoutOrderRequest,
    CheckoutOrderResponse,
    InvoiceResponse,
    SubscriptionPlanResponse,
    VerifyPaymentRequest,
    VerifyPaymentResponse,
    WorkspaceSubscriptionResponse,
    WorkspaceUsageResponse,
)

router = APIRouter(prefix="/billing", tags=["Billing"])


@router.get("/plans", response_model=List[SubscriptionPlanResponse])
def list_subscription_plans(db: Session = Depends(get_db)):
    """List public subscription plans with pricing, feature entitlements, and limits."""
    service = PlanService(db)
    return service.list_public_plans()


@router.get("/subscription", response_model=WorkspaceSubscriptionResponse)
def get_workspace_subscription(
    member: WorkspaceMember = Depends(get_active_workspace_member),
    db: Session = Depends(get_db),
):
    """Retrieve active subscription status and renewal date for workspace."""
    entitlement_service = EntitlementService(db)
    sub = entitlement_service.get_active_subscription(member.workspace_id)
    return sub


@router.get("/usage", response_model=WorkspaceUsageResponse)
def get_workspace_usage(
    member: WorkspaceMember = Depends(get_active_workspace_member),
    db: Session = Depends(get_db),
):
    """Get real-time consumption vs entitlement limits (connected accounts, publishing, team members)."""
    entitlement_service = EntitlementService(db)
    return entitlement_service.get_workspace_usage_and_limits(member.workspace_id)


@router.post("/checkout", response_model=CheckoutOrderResponse)
def create_checkout_session(
    payload: CheckoutOrderRequest,
    member: WorkspaceMember = Depends(require_permission("billing.manage")),
    db: Session = Depends(get_db),
):
    """Generate Razorpay order for client-side payment checkout modal."""
    sub_service = SubscriptionService(db)
    return sub_service.create_checkout_order(
        workspace_id=member.workspace_id,
        user=member.user,
        plan_code=payload.plan_code,
        billing_cycle=payload.billing_cycle,
    )


@router.post("/verify-payment", response_model=VerifyPaymentResponse)
def verify_payment_and_activate(
    payload: VerifyPaymentRequest,
    member: WorkspaceMember = Depends(require_permission("billing.manage")),
    db: Session = Depends(get_db),
):
    """Verify Razorpay payment signature server-side and activate workspace subscription."""
    sub_service = SubscriptionService(db)
    return sub_service.verify_and_activate_subscription(
        workspace_id=member.workspace_id,
        order_id=payload.order_id,
        payment_id=payload.payment_id,
        signature=payload.signature,
        plan_code=payload.plan_code,
        billing_cycle=payload.billing_cycle,
        actor_id=member.user_id,
    )


@router.post("/subscription/cancel", response_model=WorkspaceSubscriptionResponse)
def cancel_subscription(
    member: WorkspaceMember = Depends(require_permission("billing.manage")),
    db: Session = Depends(get_db),
):
    """Cancel subscription at the end of the current billing cycle."""
    sub_service = SubscriptionService(db)
    return sub_service.cancel_subscription(member.workspace_id, actor_id=member.user_id)


@router.post("/subscription/resume", response_model=WorkspaceSubscriptionResponse)
def resume_subscription(
    member: WorkspaceMember = Depends(require_permission("billing.manage")),
    db: Session = Depends(get_db),
):
    """Reverse pending subscription cancellation."""
    sub_service = SubscriptionService(db)
    return sub_service.resume_subscription(member.workspace_id)


@router.get("/invoices", response_model=List[InvoiceResponse])
def list_invoices(
    member: WorkspaceMember = Depends(get_active_workspace_member),
    db: Session = Depends(get_db),
):
    """List all historical invoices and payment receipts for active workspace."""
    invoice_service = InvoiceService(db)
    return invoice_service.list_workspace_invoices(member.workspace_id)


@router.get("/invoices/{invoice_id}/download")
def download_invoice(
    invoice_id: str,
    member: WorkspaceMember = Depends(get_active_workspace_member),
    db: Session = Depends(get_db),
):
    """Download plain text tax invoice receipt."""
    invoice_service = InvoiceService(db)
    inv = invoice_service.get_invoice_by_id(invoice_id, workspace_id=member.workspace_id)
    content = invoice_service.generate_invoice_text(inv)
    return Response(
        content=content,
        media_type="text/plain",
        headers={"Content-Disposition": f"attachment; filename={inv.invoice_number}.txt"},
    )
