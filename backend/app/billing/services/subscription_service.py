import json
import time
from datetime import datetime, timedelta, timezone
from decimal import Decimal
from typing import Any, Dict, Optional
from sqlalchemy.orm import Session

from app.billing.providers.razorpay_provider import RazorpayPaymentGateway
from app.billing.services.invoice_service import InvoiceService
from app.billing.services.plan_service import PlanService
from app.core.exceptions import BadRequestException, NotFoundException
from app.models.audit_log import AuditLog
from app.models.billing import WorkspaceSubscription
from app.models.user import User


class SubscriptionService:
    """Manages full SaaS subscription lifecycle, checkout sessions, and plan transitions."""

    def __init__(self, db: Session):
        self.db = db
        self.plan_service = PlanService(db)
        self.invoice_service = InvoiceService(db)
        self.gateway = RazorpayPaymentGateway()

    def create_checkout_order(
        self,
        workspace_id: str,
        user: User,
        plan_code: str,
        billing_cycle: str = "monthly",
    ) -> Dict[str, Any]:
        """Generate Razorpay order for client-side checkout modal."""
        plan = self.plan_service.get_plan_by_code(plan_code)
        if not plan.is_active:
            raise BadRequestException(f"Plan '{plan.name}' is currently unavailable.")

        price = plan.price_annual if billing_cycle == "annual" else plan.price_monthly

        if price == 0 or plan.plan_code == "free":
            # Free plan does not require payment checkout
            sub = self.activate_plan(workspace_id, plan, billing_cycle, provider_payment_id="free_tier")
            return {
                "free_tier": True,
                "message": f"Successfully activated {plan.name}.",
                "subscription_id": sub.id,
            }

        # Create checkout order with Razorpay
        receipt = f"rcpt_{workspace_id[:8]}_{int(time.time())}"
        order = self.gateway.create_order(
            amount=price,
            currency=plan.currency,
            receipt=receipt,
            notes={
                "workspace_id": workspace_id,
                "plan_code": plan_code,
                "billing_cycle": billing_cycle,
                "user_id": user.id,
            },
        )

        return {
            "order_id": order["id"],
            "amount": float(price),
            "amount_subunits": order["amount"],
            "currency": plan.currency,
            "key_id": self.gateway.key_id,
            "plan_code": plan.plan_code,
            "plan_name": plan.name,
            "billing_cycle": billing_cycle,
            "receipt": receipt,
        }

    def verify_and_activate_subscription(
        self,
        workspace_id: str,
        order_id: str,
        payment_id: str,
        signature: str,
        plan_code: str,
        billing_cycle: str = "monthly",
        actor_id: Optional[str] = None,
    ) -> Dict[str, Any]:
        """Verify payment signature server-side and activate subscription."""
        # 1. Verify Razorpay HMAC-SHA256 signature
        is_valid = self.gateway.verify_payment_signature(
            order_id=order_id,
            payment_id=payment_id,
            signature=signature,
        )
        if not is_valid:
            raise BadRequestException("Invalid payment signature. Verification failed.")

        # 2. Activate Plan in database
        plan = self.plan_service.get_plan_by_code(plan_code)
        sub = self.activate_plan(
            workspace_id=workspace_id,
            plan=plan,
            billing_cycle=billing_cycle,
            provider_payment_id=payment_id,
        )

        # 3. Generate Tax-Compliant Invoice
        price = plan.price_annual if billing_cycle == "annual" else plan.price_monthly
        inv = self.invoice_service.create_invoice_for_payment(
            workspace_id=workspace_id,
            subscription_id=sub.id,
            amount_paid=price,
            currency=plan.currency,
            plan_name=plan.name,
            billing_cycle=billing_cycle,
            period_start=sub.current_period_start,
            period_end=sub.current_period_end,
            provider_payment_id=payment_id,
        )

        # 4. Trigger Phase 6 Notification
        try:
            from app.notifications.services.notification_service import NotificationService
            notif_service = NotificationService(self.db)
            notif_service.create_notification(
                workspace_id=workspace_id,
                user_id=actor_id or "system",
                title="Subscription activated",
                message=f'Your workspace has been successfully upgraded to the {plan.name} ({billing_cycle}).',
                notification_type="account",
                metadata={"status": "success", "plan_code": plan.plan_code, "invoice_id": inv.id},
            )
        except Exception:
            pass

        # 5. Log Audit Event
        self.db.add(
            AuditLog(
                workspace_id=workspace_id,
                actor_id=actor_id,
                entity_type="subscription",
                entity_id=sub.id,
                action="activate_plan",
                metadata_json=json.dumps({
                    "plan_code": plan.plan_code,
                    "payment_id": payment_id,
                    "order_id": order_id,
                    "billing_cycle": billing_cycle,
                }),
            )
        )
        self.db.commit()

        return {
            "status": "success",
            "message": f"Successfully activated {plan.name}.",
            "subscription_id": sub.id,
            "invoice_number": inv.invoice_number,
        }

    def activate_plan(
        self,
        workspace_id: str,
        plan,
        billing_cycle: str = "monthly",
        provider_payment_id: Optional[str] = None,
    ) -> WorkspaceSubscription:
        """Internal helper to set current period dates and activate subscription."""
        now = datetime.now(timezone.utc)
        duration_days = 365 if billing_cycle == "annual" else 30
        period_end = now + timedelta(days=duration_days)

        sub = (
            self.db.query(WorkspaceSubscription)
            .filter(WorkspaceSubscription.workspace_id == workspace_id)
            .first()
        )

        if not sub:
            sub = WorkspaceSubscription(
                workspace_id=workspace_id,
                plan_id=plan.id,
                status="active",
                billing_cycle=billing_cycle,
                current_period_start=now,
                current_period_end=period_end,
                cancel_at_period_end=False,
                provider="razorpay",
                provider_subscription_id=provider_payment_id,
            )
            self.db.add(sub)
        else:
            sub.plan_id = plan.id
            sub.status = "active"
            sub.billing_cycle = billing_cycle
            sub.current_period_start = now
            sub.current_period_end = period_end
            sub.cancel_at_period_end = False
            if provider_payment_id:
                sub.provider_subscription_id = provider_payment_id

        self.db.commit()
        self.db.refresh(sub)
        return sub

    def cancel_subscription(self, workspace_id: str, actor_id: Optional[str] = None) -> WorkspaceSubscription:
        """Cancel subscription at end of billing period without immediate data removal."""
        sub = (
            self.db.query(WorkspaceSubscription)
            .filter(WorkspaceSubscription.workspace_id == workspace_id)
            .first()
        )
        if not sub:
            raise NotFoundException("WorkspaceSubscription", workspace_id)

        sub.cancel_at_period_end = True
        sub.cancelled_at = datetime.now(timezone.utc)
        self.db.commit()
        self.db.refresh(sub)

        # Trigger notification
        try:
            from app.notifications.services.notification_service import NotificationService
            notif_service = NotificationService(self.db)
            notif_service.create_notification(
                workspace_id=workspace_id,
                user_id=actor_id or "system",
                title="Subscription cancelled",
                message="Your subscription will remain active until the end of the current billing cycle.",
                notification_type="account",
                metadata={"status": "cancelled", "end_date": sub.current_period_end.isoformat()},
            )
        except Exception:
            pass

        return sub

    def resume_subscription(self, workspace_id: str) -> WorkspaceSubscription:
        """Reverse scheduled cancellation before current period ends."""
        sub = (
            self.db.query(WorkspaceSubscription)
            .filter(WorkspaceSubscription.workspace_id == workspace_id)
            .first()
        )
        if not sub:
            raise NotFoundException("WorkspaceSubscription", workspace_id)

        sub.cancel_at_period_end = False
        sub.cancelled_at = None
        self.db.commit()
        self.db.refresh(sub)
        return sub

