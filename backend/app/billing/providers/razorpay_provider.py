import hashlib
import hmac
import logging
from decimal import Decimal
from typing import Any, Dict, Optional
import httpx

from app.billing.providers.base_gateway import BasePaymentGateway
from app.core.config import settings

logger = logging.getLogger(__name__)


class RazorpayPaymentGateway(BasePaymentGateway):
    """Production Razorpay integration supporting both Live API and Sandbox/Test modes."""

    def __init__(
        self,
        key_id: Optional[str] = None,
        key_secret: Optional[str] = None,
        webhook_secret: Optional[str] = None,
    ):
        self.key_id = key_id or getattr(settings, "RAZORPAY_KEY_ID", "rzp_test_mock_key_id")
        self.key_secret = key_secret or getattr(settings, "RAZORPAY_KEY_SECRET", "mock_razorpay_secret")
        self.webhook_secret = webhook_secret or getattr(settings, "RAZORPAY_WEBHOOK_SECRET", "mock_webhook_secret")
        self.base_url = "https://api.razorpay.com/v1"

    @property
    def provider_name(self) -> str:
        return "razorpay"

    @property
    def is_sandbox(self) -> bool:
        return self.key_id.startswith("rzp_test") or "mock" in self.key_secret

    def create_customer(
        self,
        email: str,
        name: Optional[str] = None,
        contact: Optional[str] = None,
        notes: Optional[Dict[str, Any]] = None,
    ) -> Dict[str, Any]:
        """Create or register customer in Razorpay."""
        if self.is_sandbox and "mock" in self.key_secret:
            return {
                "id": f"cust_rzp_{abs(hash(email)) % 10000000}",
                "name": name or "Valued Customer",
                "email": email,
                "contact": contact or "+919876543210",
                "created_at": 1700000000,
            }

        auth = (self.key_id, self.key_secret)
        payload = {"email": email, "fail_existing": 0}
        if name:
            payload["name"] = name
        if contact:
            payload["contact"] = contact
        if notes:
            payload["notes"] = notes

        with httpx.Client(timeout=15.0) as client:
            resp = client.post(f"{self.base_url}/customers", json=payload, auth=auth)
            resp.raise_for_status()
            return resp.json()

    def create_order(
        self,
        amount: Decimal,
        currency: str,
        receipt: str,
        notes: Optional[Dict[str, Any]] = None,
    ) -> Dict[str, Any]:
        """Create order in Razorpay (amount in currency sub-units e.g. paise)."""
        # Razorpay expects integer in paise (e.g. 4900 for 49.00 INR)
        amount_subunits = int(amount * 100)

        if self.is_sandbox and "mock" in self.key_secret:
            return {
                "id": f"order_rzp_{receipt[:12]}_{amount_subunits}",
                "entity": "order",
                "amount": amount_subunits,
                "amount_paid": 0,
                "amount_due": amount_subunits,
                "currency": currency.upper(),
                "receipt": receipt,
                "status": "created",
                "attempts": 0,
                "notes": notes or {},
            }

        auth = (self.key_id, self.key_secret)
        payload = {
            "amount": amount_subunits,
            "currency": currency.upper(),
            "receipt": receipt,
            "notes": notes or {},
        }

        with httpx.Client(timeout=15.0) as client:
            resp = client.post(f"{self.base_url}/orders", json=payload, auth=auth)
            resp.raise_for_status()
            return resp.json()

    def verify_payment_signature(
        self,
        order_id: str,
        payment_id: str,
        signature: str,
    ) -> bool:
        """Verify Razorpay payment signature: HMAC-SHA256(order_id|payment_id, key_secret)."""
        if not signature or not order_id or not payment_id:
            return False

        message = f"{order_id}|{payment_id}".encode("utf-8")
        generated_signature = hmac.new(
            self.key_secret.encode("utf-8"),
            message,
            hashlib.sha256,
        ).hexdigest()

        return hmac.compare_digest(generated_signature, signature)

    def fetch_payment(self, payment_id: str) -> Dict[str, Any]:
        """Fetch captured payment status from Razorpay."""
        if self.is_sandbox and "mock" in self.key_secret:
            return {
                "id": payment_id,
                "entity": "payment",
                "amount": 4900,
                "currency": "INR",
                "status": "captured",
                "method": "card",
                "captured": True,
            }

        auth = (self.key_id, self.key_secret)
        with httpx.Client(timeout=15.0) as client:
            resp = client.get(f"{self.base_url}/payments/{payment_id}", auth=auth)
            resp.raise_for_status()
            return resp.json()

    def create_refund(
        self,
        payment_id: str,
        amount: Decimal,
        currency: str,
        reason: Optional[str] = None,
        notes: Optional[Dict[str, Any]] = None,
    ) -> Dict[str, Any]:
        """Create a full or partial refund for a captured payment."""
        amount_subunits = int(amount * 100)

        if self.is_sandbox and "mock" in self.key_secret:
            return {
                "id": f"rfnd_rzp_{payment_id[:10]}_{amount_subunits}",
                "entity": "refund",
                "amount": amount_subunits,
                "currency": currency.upper(),
                "payment_id": payment_id,
                "status": "processed",
                "notes": notes or {},
            }

        auth = (self.key_id, self.key_secret)
        payload = {
            "amount": amount_subunits,
            "notes": notes or {},
        }
        if reason:
            payload["notes"]["reason"] = reason

        with httpx.Client(timeout=15.0) as client:
            resp = client.post(f"{self.base_url}/payments/{payment_id}/refund", json=payload, auth=auth)
            resp.raise_for_status()
            return resp.json()

    def verify_webhook_signature(
        self,
        payload_body: bytes,
        signature_header: str,
        secret: Optional[str] = None,
    ) -> bool:
        """Verify Razorpay webhook signature header (X-Razorpay-Signature)."""
        webhook_sec = secret or self.webhook_secret
        if not signature_header or not webhook_sec:
            return False

        expected = hmac.new(webhook_sec.encode("utf-8"), payload_body, hashlib.sha256).hexdigest()
        return hmac.compare_digest(expected, signature_header)

