from sqlalchemy import Boolean, Column, DateTime, ForeignKey, Integer, Numeric, String, Text
from sqlalchemy.orm import relationship
from app.core.database import Base
from app.models.base import TimestampMixin, UUIDMixin


class SubscriptionPlan(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "subscription_plans"

    plan_code = Column(String(32), unique=True, index=True, nullable=False)  # free, starter, pro, business
    name = Column(String(64), nullable=False)
    description = Column(String(255), nullable=True)
    price_monthly = Column(Numeric(10, 2), default=0.00, nullable=False)
    price_annual = Column(Numeric(10, 2), default=0.00, nullable=False)
    currency = Column(String(3), default="INR", nullable=False)
    trial_days = Column(Integer, default=0, nullable=False)

    # Entitlements & Quotas
    max_social_accounts = Column(Integer, default=3, nullable=False)
    max_team_members = Column(Integer, default=1, nullable=False)
    monthly_published_targets = Column(Integer, default=30, nullable=False)
    max_storage_mb = Column(Integer, default=500, nullable=False)
    analytics_history_days = Column(Integer, default=7, nullable=False)
    export_enabled = Column(Boolean, default=False, nullable=False)
    features_json = Column(Text, nullable=True)

    is_active = Column(Boolean, default=True, nullable=False)
    is_public = Column(Boolean, default=True, nullable=False)
    display_order = Column(Integer, default=0, nullable=False)

    # Relationships
    subscriptions = relationship("WorkspaceSubscription", back_populates="plan")


class WorkspaceSubscription(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "workspace_subscriptions"

    workspace_id = Column(String(36), ForeignKey("workspaces.id", ondelete="CASCADE"), unique=True, nullable=False)
    plan_id = Column(String(36), ForeignKey("subscription_plans.id", ondelete="RESTRICT"), nullable=False)
    status = Column(String(32), default="active", nullable=False)  # active, trialing, past_due, unpaid, paused, cancel_at_period_end, cancelled, expired, incomplete
    billing_cycle = Column(String(16), default="monthly", nullable=False)  # monthly, annual
    current_period_start = Column(DateTime(timezone=True), nullable=False)
    current_period_end = Column(DateTime(timezone=True), nullable=False)
    trial_end = Column(DateTime(timezone=True), nullable=True)
    cancel_at_period_end = Column(Boolean, default=False, nullable=False)
    cancelled_at = Column(DateTime(timezone=True), nullable=True)

    # Payment Gateway Metadata
    provider = Column(String(32), default="razorpay", nullable=False)
    provider_subscription_id = Column(String(255), nullable=True, index=True)
    provider_customer_id = Column(String(255), nullable=True, index=True)

    # Relationships
    workspace = relationship("Workspace", back_populates="subscription")
    plan = relationship("SubscriptionPlan", back_populates="subscriptions")


class BillingCustomer(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "billing_customers"

    workspace_id = Column(String(36), ForeignKey("workspaces.id", ondelete="CASCADE"), unique=True, nullable=False)
    provider = Column(String(32), default="razorpay", nullable=False)
    provider_customer_id = Column(String(255), unique=True, index=True, nullable=False)
    billing_email = Column(String(255), nullable=False)
    billing_name = Column(String(255), nullable=True)
    company_name = Column(String(255), nullable=True)
    gstin = Column(String(32), nullable=True)
    address_line1 = Column(String(255), nullable=True)
    address_line2 = Column(String(255), nullable=True)
    city = Column(String(100), nullable=True)
    state = Column(String(100), nullable=True)
    postal_code = Column(String(20), nullable=True)
    country = Column(String(2), default="IN", nullable=False)


class Invoice(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "invoices"

    workspace_id = Column(String(36), ForeignKey("workspaces.id", ondelete="CASCADE"), nullable=False, index=True)
    subscription_id = Column(String(36), nullable=True, index=True)
    invoice_number = Column(String(64), unique=True, index=True, nullable=False)
    subtotal_amount = Column(Numeric(10, 2), default=0.00, nullable=False)
    tax_amount = Column(Numeric(10, 2), default=0.00, nullable=False)
    amount_paid = Column(Numeric(10, 2), nullable=False)
    currency = Column(String(3), default="INR", nullable=False)
    status = Column(String(32), default="paid", nullable=False)  # paid, open, void, uncollectible, refunded
    payment_method = Column(String(32), default="razorpay", nullable=False)
    provider_payment_id = Column(String(255), nullable=True, index=True)
    invoice_url = Column(String(512), nullable=True)
    paid_at = Column(DateTime(timezone=True), nullable=True)
    billing_period_start = Column(DateTime(timezone=True), nullable=True)
    billing_period_end = Column(DateTime(timezone=True), nullable=True)
    items_json = Column(Text, nullable=True)

    # Relationships
    refunds = relationship("PaymentRefund", back_populates="invoice", cascade="all, delete-orphan")


class PaymentRefund(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "payment_refunds"

    workspace_id = Column(String(36), ForeignKey("workspaces.id", ondelete="CASCADE"), nullable=False, index=True)
    invoice_id = Column(String(36), ForeignKey("invoices.id", ondelete="CASCADE"), nullable=False, index=True)
    provider_refund_id = Column(String(255), unique=True, index=True, nullable=False)
    amount = Column(Numeric(10, 2), nullable=False)
    currency = Column(String(3), default="INR", nullable=False)
    reason = Column(String(255), nullable=True)
    status = Column(String(32), default="processed", nullable=False)  # pending, processed, failed
    processed_at = Column(DateTime(timezone=True), nullable=True)

    # Relationships
    invoice = relationship("Invoice", back_populates="refunds")


class PaymentEvent(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "payment_events"

    provider_event_id = Column(String(255), unique=True, index=True, nullable=False)
    event_type = Column(String(64), nullable=False)
    payload_json = Column(Text, nullable=False)
    processed = Column(Boolean, default=False, nullable=False)


class UsageRecord(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "usage_records"

    workspace_id = Column(String(36), ForeignKey("workspaces.id", ondelete="CASCADE"), nullable=False, index=True)
    metric_name = Column(String(64), nullable=False, index=True)  # published_targets, media_storage_mb, social_accounts, team_members
    quantity = Column(Integer, default=0, nullable=False)
    period_start = Column(DateTime(timezone=True), nullable=False)
    period_end = Column(DateTime(timezone=True), nullable=False)
