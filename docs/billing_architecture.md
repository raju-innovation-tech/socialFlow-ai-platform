# SocialFlow AI – Billing & SaaS Monetization Architecture (Phase 7)

## 1. Architectural Overview

SocialFlow AI implements a multi-tier SaaS billing and subscription engine built around the following principles:
- **Gateway Abstraction**: `BasePaymentGateway` decouples application logic from payment providers, with `RazorpayPaymentGateway` as the primary Indian-market payment gateway and extensibility for Stripe.
- **Provider-Verified Transactions**: Payments are never trusted solely based on frontend callbacks. All payment activations require cryptographically verified server-side HMAC-SHA256 signatures or verified webhook events.
- **Zero-AI Guarantee**: Pure deterministic arithmetic and official financial records; no simulated or AI-generated billing data.
- **Strict Tenant Partitioning**: Subscriptions, usage records, and invoices are strictly isolated by `workspace_id`.
- **Financial Auditability**: All monetary values use high-precision decimals (`NUMERIC(10, 2)`), explicit ISO-4217 currencies (default: `INR`), and immutable payment audit trails.

---

## 2. Directory Structure

```
backend/app/billing/
├── __init__.py
├── providers/
│   ├── base_gateway.py        # Abstract gateway interface
│   └── razorpay_provider.py    # Official Razorpay SDK / API integration
└── services/
    ├── plan_service.py         # Plan catalog & configuration
    ├── entitlement_service.py  # Quota resolution & limit enforcement
    ├── subscription_service.py # Lifecycle transitions & checkout
    ├── invoice_service.py      # GST invoice generation & downloads
    └── refund_service.py       # Gateway refunds & audit logging
```

---

## 3. Subscription Tiers & Pricing Model

| Plan Code | Name | Monthly (INR) | Annual (INR) | Connected Accounts | Monthly Publishing | Team Members | Storage (MB) | Analytics |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `free` | Free Starter | ₹0 | ₹0 | 3 | 30 | 1 | 500 MB | 7 Days (Basic) |
| `starter` | Starter Plan | ₹999 | ₹9,990 | 7 | 150 | 3 | 5,000 MB | 30 Days (Extended) |
| `pro` | Professional Plan | ₹2,499 | ₹24,990 | 15 | 500 | 5 | 25,000 MB | 90 Days (Advanced) |
| `business` | Business Enterprise| ₹6,999 | ₹69,990 | 50 | 2,500 | 20 | 100,000 MB | 365 Days (Full) |

