# SocialFlow AI – Payment Security Architecture (Phase 7)

## 1. Zero Trust Client Principles
- **No Client-Side Finality**: A client success callback never activates subscriptions directly. All payment state transitions are authenticated via server-side HMAC-SHA256 signature verification.
- **Cardholder Data Isolation**: SocialFlow AI never receives, handles, transmits, or stores card numbers, CVVs, or bank credentials. All payment details are collected securely by PCI-DSS compliant Razorpay hosted fields.

---

## 2. Idempotency & Webhook Protection
- **Order Receipts & Idempotency Keys**: Every payment order generates a deterministic unique receipt key (`rcpt_{workspace_id}_{timestamp}`).
- **Duplicate Webhook Prevention**: Webhook event IDs are recorded in `payment_events`. Incoming events are checked with `SELECT ... WHERE provider_event_id = :id` to prevent duplicate ledger postings.
- **Refund Protection**: The refund service checks existing processed refunds for the invoice to prevent double refunds.

