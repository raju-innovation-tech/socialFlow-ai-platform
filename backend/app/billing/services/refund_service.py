import json
from datetime import datetime, timezone
from decimal import Decimal
from typing import Any, Dict, Optional
from sqlalchemy.orm import Session

from app.billing.providers.razorpay_provider import RazorpayPaymentGateway
from app.core.exceptions import BadRequestException, NotFoundException
from app.models.audit_log import AuditLog
from app.models.billing import Invoice, PaymentRefund


class RefundService:
    """Orchestrates payment refunds with payment gateway reconciliation and audit logging."""

    def __init__(self, db: Session):
        self.db = db
        self.gateway = RazorpayPaymentGateway()

    def issue_refund(
        self,
        invoice_id: str,
        reason: Optional[str] = None,
        actor_id: Optional[str] = None,
    ) -> Dict[str, Any]:
        """Process official refund for an invoice through payment gateway."""
        invoice = self.db.query(Invoice).filter(Invoice.id == invoice_id).first()
        if not invoice:
            raise NotFoundException("Invoice", invoice_id)

        if invoice.status == "refunded":
            raise BadRequestException("Invoice has already been refunded.")

        if invoice.amount_paid <= 0:
            raise BadRequestException("Cannot refund zero-value invoice.")

        payment_id = invoice.provider_payment_id or f"pay_mock_{invoice.id[:8]}"

        # Check existing refund to prevent duplicate refunds
        existing = self.db.query(PaymentRefund).filter(PaymentRefund.invoice_id == invoice.id).first()
        if existing and existing.status == "processed":
            raise BadRequestException("A processed refund already exists for this invoice.")

        # 1. Call payment gateway
        gateway_res = self.gateway.create_refund(
            payment_id=payment_id,
            amount=invoice.amount_paid,
            currency=invoice.currency,
            reason=reason,
        )

        refund_id = gateway_res.get("id", f"rfnd_{invoice.id[:8]}")

        # 2. Record PaymentRefund in DB
        refund = PaymentRefund(
            workspace_id=invoice.workspace_id,
            invoice_id=invoice.id,
            provider_refund_id=refund_id,
            amount=invoice.amount_paid,
            currency=invoice.currency,
            reason=reason or "Customer requested refund",
            status="processed",
            processed_at=datetime.now(timezone.utc),
        )
        self.db.add(refund)

        # 3. Mark invoice as refunded
        invoice.status = "refunded"
        self.db.commit()
        self.db.refresh(refund)

        # 4. Trigger Phase 6 Notification
        try:
            from app.notifications.services.notification_service import NotificationService
            notif_service = NotificationService(self.db)
            notif_service.create_notification(
                workspace_id=invoice.workspace_id,
                user_id=actor_id or "system",
                title="Refund processed",
                message=f"Refund of {invoice.currency} {invoice.amount_paid:.2f} for invoice {invoice.invoice_number} has been processed successfully.",
                notification_type="account",
                metadata={"status": "refunded", "refund_id": refund.id},
            )
        except Exception:
            pass

        # 5. Record Platform Audit Log
        self.db.add(
            AuditLog(
                workspace_id=invoice.workspace_id,
                actor_id=actor_id,
                entity_type="payment_refund",
                entity_id=refund.id,
                action="issue_refund",
                metadata_json=json.dumps({
                    "invoice_number": invoice.invoice_number,
                    "amount": float(invoice.amount_paid),
                    "currency": invoice.currency,
                    "provider_refund_id": refund_id,
                }),
            )
        )
        self.db.commit()

        return {
            "status": "success",
            "refund_id": refund.id,
            "provider_refund_id": refund_id,
            "amount": float(invoice.amount_paid),
            "currency": invoice.currency,
            "message": "Refund processed successfully.",
        }

