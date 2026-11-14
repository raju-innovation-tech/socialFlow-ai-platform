from sqlalchemy import Boolean, Column, DateTime, ForeignKey, Integer, Numeric, String, Text
from sqlalchemy.orm import relationship
from app.core.database import Base
from app.models.base import TimestampMixin, UUIDMixin


class SubscriptionPlan(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "subscription_plans"

    plan_code = Column(String(32), unique=True, index=True, nullable=False)  # free, starter, pro, enterprise
    name = Column(String(64), nullable=False)
    price_monthly = Column(Numeric(10, 2), default=0.00, nullable=False)
    price_annual = Column(Numeric(10, 2), default=0.00, nullable=False)
    currency = Column(String(3), default="USD", nullable=False)
    ai_credits_monthly = Column(Integer, default=500, nullable=False)
    max_social_accounts = Column(Integer, default=3, nullable=False)
    max_team_members = Column(Integer, default=2, nullable=False)
    is_active = Column(Boolean, default=True, nullable=False)

    # Relationships
    subscriptions = relationship("WorkspaceSubscription", back_populates="plan")


class WorkspaceSubscription(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "workspace_subscriptions"

    workspace_id = Column(String(36), ForeignKey("workspaces.id", ondelete="CASCADE"), unique=True, nullable=False)
    plan_id = Column(String(36), ForeignKey("subscription_plans.id", ondelete="RESTRICT"), nullable=False)
    status = Column(String(32), default="active", nullable=False)  # active, trialing, past_due, canceled
    current_period_start = Column(DateTime(timezone=True), nullable=False)
    current_period_end = Column(DateTime(timezone=True), nullable=False)
    cancel_at_period_end = Column(Boolean, default=False, nullable=False)

    # Relationships
    workspace = relationship("Workspace", back_populates="subscription")
    plan = relationship("SubscriptionPlan", back_populates="subscriptions")


class BillingCustomer(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "billing_customers"

    workspace_id = Column(String(36), ForeignKey("workspaces.id", ondelete="CASCADE"), unique=True, nullable=False)
    provider = Column(String(32), default="stripe", nullable=False)
    provider_customer_id = Column(String(255), unique=True, index=True, nullable=False)
    billing_email = Column(String(255), nullable=False)
    billing_name = Column(String(255), nullable=True)
    country = Column(String(2), default="US", nullable=False)


class Invoice(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "invoices"

    workspace_id = Column(String(36), ForeignKey("workspaces.id", ondelete="CASCADE"), nullable=False, index=True)
    invoice_number = Column(String(64), unique=True, index=True, nullable=False)
    amount_paid = Column(Numeric(10, 2), nullable=False)
    currency = Column(String(3), default="USD", nullable=False)
    status = Column(String(32), default="paid", nullable=False)  # paid, open, void, uncollectible
    invoice_url = Column(String(512), nullable=True)
    paid_at = Column(DateTime(timezone=True), nullable=True)


class PaymentEvent(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "payment_events"

    provider_event_id = Column(String(255), unique=True, index=True, nullable=False)
    event_type = Column(String(64), nullable=False)
    payload_json = Column(Text, nullable=False)
    processed = Column(Boolean, default=False, nullable=False)


class UsageRecord(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "usage_records"

    workspace_id = Column(String(36), ForeignKey("workspaces.id", ondelete="CASCADE"), nullable=False, index=True)
    metric_name = Column(String(64), nullable=False, index=True)  # ai_credits, posts_published
    quantity = Column(Integer, default=0, nullable=False)
    period_start = Column(DateTime(timezone=True), nullable=False)
    period_end = Column(DateTime(timezone=True), nullable=False)

