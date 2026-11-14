from abc import ABC, abstractmethod
from decimal import Decimal
from typing import Any, Dict, Optional


class BasePaymentGateway(ABC):
    """Abstract payment gateway interface for SaaS billing."""

    @property
    @abstractmethod
    def provider_name(self) -> str:
        """Unique provider identifier (e.g. 'razorpay', 'stripe')."""
        pass

    @abstractmethod
    def create_customer(
        self,
        email: str,
        name: Optional[str] = None,
        contact: Optional[str] = None,
        notes: Optional[Dict[str, Any]] = None,
    ) -> Dict[str, Any]:
        """Create or locate a customer in the payment gateway."""
        pass

    @abstractmethod
    def create_order(
        self,
        amount: Decimal,
        currency: str,
        receipt: str,
        notes: Optional[Dict[str, Any]] = None,
    ) -> Dict[str, Any]:
        """Create a payment order/session for client checkout."""
        pass

    @abstractmethod
    def verify_payment_signature(
        self,
        order_id: str,
        payment_id: str,
        signature: str,
    ) -> bool:
        """Verify client payment response signature using gateway secret."""
        pass

    @abstractmethod
    def fetch_payment(self, payment_id: str) -> Dict[str, Any]:
        """Fetch captured payment details and settlement status."""
        pass

    @abstractmethod
    def create_refund(
        self,
        payment_id: str,
        amount: Decimal,
        currency: str,
        reason: Optional[str] = None,
        notes: Optional[Dict[str, Any]] = None,
    ) -> Dict[str, Any]:
        """Issue full or partial refund through gateway."""
        pass

    @abstractmethod
    def verify_webhook_signature(
        self,
        payload_body: bytes,
        signature_header: str,
        secret: Optional[str] = None,
    ) -> bool:
        """Verify HMAC webhook payload signature."""
        pass

