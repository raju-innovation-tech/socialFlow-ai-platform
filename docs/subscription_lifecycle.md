# SocialFlow AI – Subscription Lifecycle Specification (Phase 7)

## 1. Supported States

| State | Definition | Entitlement Access |
| :--- | :--- | :--- |
| `trialing` | Workspace is evaluating paid plan during trial window. | Full plan entitlements. |
| `active` | Active subscription with verified payment. | Full plan entitlements. |
| `past_due` | Payment renewal failed; in grace period. | Full plan entitlements with billing warning. |
| `unpaid` | Grace period expired after multiple payment retries. | Restricted to Free Tier limits. |
| `paused` | Temporarily paused by customer or Super Admin. | Read-only access; publishing paused. |
| `cancel_at_period_end` | Customer requested cancellation; valid until `current_period_end`. | Full entitlements until period ends. |
| `cancelled` | Subscription terminated; billing cycle ended. | Automatically reverted to Free Tier. |
| `expired` | Trial period ended without payment conversion. | Automatically reverted to Free Tier. |

---

## 2. Transition Rules

1. **Free to Paid Upgrade**:
   - Customer initiates checkout -> Razorpay order created.
   - Client completes payment -> Backend verifies HMAC signature.
   - Subscription updated: `status = 'active'`, `current_period_start = now`, `current_period_end = now + 30/365 days`.
   - Tax-compliant invoice generated; in-app notification sent.
2. **Cancellation**:
   - `POST /api/v1/billing/subscription/cancel`
   - Sets `cancel_at_period_end = True`, records `cancelled_at = now`.
   - Workspace keeps full paid access until `current_period_end`.
3. **Resumption**:
   - `POST /api/v1/billing/subscription/resume`
   - Sets `cancel_at_period_end = False`, clears `cancelled_at`.

