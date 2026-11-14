import json
from datetime import datetime, timezone
from decimal import Decimal
from typing import Any, Dict, List, Optional
from sqlalchemy.orm import Session

from app.core.exceptions import NotFoundException
from app.models.billing import Invoice


class InvoiceService:
    """Manages SaaS invoices, GST tax breakdowns, and payment audit records."""

    def __init__(self, db: Session):
        self.db = db

    def list_workspace_invoices(self, workspace_id: str) -> List[Invoice]:
        """Fetch all historical invoices strictly scoped to workspace."""
        return (
            self.db.query(Invoice)
            .filter(Invoice.workspace_id == workspace_id)
            .order_by(Invoice.created_at.desc())
            .all()
        )

    def get_invoice_by_id(self, invoice_id: str, workspace_id: Optional[str] = None) -> Invoice:
        query = self.db.query(Invoice).filter(Invoice.id == invoice_id)
        if workspace_id:
            query = query.filter(Invoice.workspace_id == workspace_id)
        inv = query.first()
        if not inv:
            raise NotFoundException("Invoice", invoice_id)
        return inv

    def create_invoice_for_payment(
        self,
        workspace_id: str,
        subscription_id: str,
        amount_paid: Decimal,
        currency: str,
        plan_name: str,
        billing_cycle: str,
        period_start: datetime,
        period_end: datetime,
        provider_payment_id: Optional[str] = None,
        payment_method: str = "razorpay",
    ) -> Invoice:
        """Create a tax-compliant SaaS invoice record with 18% GST breakdown."""
        # Standard Indian GST: 18% inclusive in SaaS billing
        # Subtotal = Total / 1.18; Tax = Total - Subtotal
        total = Decimal(str(amount_paid))
        if total > 0:
            subtotal = round(total / Decimal("1.18"), 2)
            tax = total - subtotal
        else:
            subtotal = Decimal("0.00")
            tax = Decimal("0.00")

        now = datetime.now(timezone.utc)
        inv_number = f"INV-{now.year}{now.month:02d}-{now.strftime('%d%H%M%S')}"

        items = [
            {
                "description": f"SocialFlow AI {plan_name} ({billing_cycle.capitalize()} Subscription)",
                "amount": float(subtotal),
                "tax_rate": "18% GST",
                "tax_amount": float(tax),
                "total": float(total),
            }
        ]

        invoice = Invoice(
            workspace_id=workspace_id,
            subscription_id=subscription_id,
            invoice_number=inv_number,
            subtotal_amount=subtotal,
            tax_amount=tax,
            amount_paid=total,
            currency=currency.upper(),
            status="paid",
            payment_method=payment_method,
            provider_payment_id=provider_payment_id,
            paid_at=now,
            billing_period_start=period_start,
            billing_period_end=period_end,
            items_json=json.dumps(items),
        )
        self.db.add(invoice)
        self.db.commit()
        self.db.refresh(invoice)
        return invoice

    def generate_invoice_text(self, invoice: Invoice) -> str:
        """Generate formatted textual invoice summary."""
        lines = [
            "============================================================",
            "                   SOCIALFLOW AI TAX INVOICE                ",
            "============================================================",
            f"Invoice Number: {invoice.invoice_number}",
            f"Date of Issue:  {invoice.paid_at.strftime('%Y-%m-%d %H:%M:%S') if invoice.paid_at else 'N/A'}",
            f"Workspace ID:   {invoice.workspace_id}",
            f"Payment Method: {invoice.payment_method.capitalize()} ({invoice.provider_payment_id or 'Online'})",
            f"Payment Status: {invoice.status.upper()}",
            "------------------------------------------------------------",
            f"Billing Period: {invoice.billing_period_start.strftime('%Y-%m-%d') if invoice.billing_period_start else ''} to {invoice.billing_period_end.strftime('%Y-%m-%d') if invoice.billing_period_end else ''}",
            "------------------------------------------------------------",
            f"Subtotal:       {invoice.currency} {invoice.subtotal_amount:.2f}",
            f"GST (18%):      {invoice.currency} {invoice.tax_amount:.2f}",
            f"TOTAL PAID:     {invoice.currency} {invoice.amount_paid:.2f}",
            "============================================================",
            "Thank you for choosing SocialFlow AI!",
        ]
        return "\n".join(lines)

