# SocialFlow AI – Phase 7 Audit: Billing, Subscriptions & Super Admin

## 1. Executive Summary
This document provides a comprehensive audit of the SocialFlow AI project prior to developing **Phase 7: SaaS Monetization & Platform Administration**. 

### Verified Foundation
- **Phase 1 (Flutter UI)**: 47 production-grade Flutter screens adhering strictly to the Dark Premium, Glassmorphism, and Bento Grid design systems. All unit tests passing.
- **Phase 2 (FastAPI + PostgreSQL + Redis)**: Fully migrated relational database schema with PostgreSQL, Alembic migrations, Redis caching, and health verification.
- **Phase 3 (Authentication, Multi-tenancy, RBAC)**: Strict workspace boundaries (`X-Workspace-ID`), tenant isolation, 6 granular workspace roles (`owner`, `admin`, `editor`, `approver`, `analyst`, `viewer`), and separate `is_super_admin` flag on `User`.
- **Phase 4 (7 Social Integrations)**: Official OAuth 2.0 & Bot connections for LinkedIn, Facebook, Instagram, YouTube, X (Twitter), WhatsApp Business, and Telegram.
- **Phase 5 (Publishing & Scheduling)**: Distributed Redis idempotency locks, target-specific retries, background `publishing_worker`, and multi-target post orchestration.
- **Phase 6 (Analytics & Notifications)**: Truthful platform API analytics providers, multi-channel notifications (In-App, Email, Push device tokens), `analytics_sync_worker`, and 36/36 backend tests passing.

---

## 2. Existing Billing & Admin Code Audit

### A. Database Models (`backend/app/models/billing.py` & `audit_log.py`)
| Model | Status | Attributes | Missing in Phase 7 |
| :--- | :--- | :--- | :--- |
| `SubscriptionPlan` | Partially Defined | `plan_code`, `name`, `price_monthly`, `price_annual`, `currency`, `max_social_accounts`, `max_team_members`, `is_active` | Monthly published targets limit, media storage limit, features JSON / entitlements |
| `WorkspaceSubscription` | Partially Defined | `workspace_id`, `plan_id`, `status`, `current_period_start`, `current_period_end`, `cancel_at_period_end` | Provider subscription ID, trial dates, grace period end, payment failure counter |
| `BillingCustomer` | Partially Defined | `workspace_id`, `provider`, `provider_customer_id`, `billing_email`, `country` | GSTIN, tax ID, business legal name, billing address |
| `Invoice` | Partially Defined | `workspace_id`, `invoice_number`, `amount_paid`, `currency`, `status`, `invoice_url`, `paid_at` | Subtotal, GST/tax amount, line items JSON, PDF invoice generation |
| `PaymentEvent` | Defined | `provider_event_id`, `event_type`, `payload_json`, `processed` | Razorpay webhook idempotency and status reconciliation |
| `UsageRecord` | Defined | `workspace_id`, `metric_name`, `quantity`, `period_start`, `period_end` | Real-time entitlement meter service & limit enforcement |
| `AuditLog` | Defined | `workspace_id`, `actor_id`, `entity_type`, `entity_id`, `action`, `metadata_json`, `ip_address`, `logged_at` | Platform-level Super Admin audit events |

### B. Backend Routers
- `backend/app/api/v1/billing.py`: Currently provides basic GET `/plans` and mock `/subscription`. Needs full implementation of checkout, payment verification (Razorpay), subscription upgrades/downgrades/cancellation, invoices, usage, and entitlements.
- `backend/app/api/v1/admin.py`: Currently provides basic GET `/users`, `/workspaces`, and `/roles`. Needs expansion to full Super Admin API namespace: user suspension/reactivation, workspace suspension/reactivation, plan creation/editing, payment/refund management, integration health, system monitoring, and platform audit logs.

### C. Flutter Frontend Screens
- `flutter_admin/lib/features/billing/screens/`:
  - `subscription_usage_screen.dart`: Needs live binding to `/api/v1/billing/subscription` and `/api/v1/billing/usage`.
  - `billing_history_screen.dart`: Needs live binding to `/api/v1/billing/invoices` and `/api/v1/billing/payments`.
- `flutter_admin/lib/features/super_admin/screens/`:
  - `super_admin_dashboard_screen.dart`: Needs 6 module tiles matching user diagram: User Management, Workspace Management, Payments & Refunds, Plan Management, System Monitoring, and Audit Logs.
  - `user_management_screen.dart`: Connect suspend/reactivate actions.
  - `workspace_management_screen.dart`: Connect suspend/reactivate actions.
  - `api_health_screen.dart`: Connect live platform integration health.
  - `system_logs_screen.dart`: Connect real audit logs and system monitoring.

---

## 3. Implementation Plan for Phase 7

1. **Database Schema Enhancements & Alembic Migration**:
   - Add feature entitlement fields and quotas to `SubscriptionPlan` (`monthly_published_targets`, `max_storage_mb`, `features_json`, `trial_days`).
   - Add Razorpay fields to `WorkspaceSubscription` and `PaymentEvent`.
   - Add GSTIN and billing address fields to `BillingCustomer` and `Invoice`.
   - Run Alembic migration to update PostgreSQL cleanly without data loss.
2. **Modular Billing Architecture**:
   - `backend/app/billing/providers/base_gateway.py` (Gateway abstraction)
   - `backend/app/billing/providers/razorpay_provider.py` (Official Razorpay SDK / API integration with HMAC-SHA256 signature verification)
   - `backend/app/billing/services/` (`plan_service.py`, `subscription_service.py`, `entitlement_service.py`, `payment_service.py`, `invoice_service.py`, `usage_service.py`, `refund_service.py`)
   - `backend/app/billing/webhooks/razorpay_webhook.py` (Idempotent signature-verified webhook handler)
3. **Super Admin Authorization & Services**:
   - `backend/app/admin/services/admin_service.py` (Platform stats, MRR/ARR, user/workspace suspensions, audit logs, system health)
   - Super Admin bootstrap command: `python -m app.admin.scripts.bootstrap_super_admin`
4. **Backend API Endpoints**:
   - Update `backend/app/api/v1/billing.py` (Customer billing & subscription management)
   - Update `backend/app/api/v1/admin.py` (Platform administration & monitoring)
5. **Phase 6 Notification Hooks**:
   - Trigger billing notifications on subscription activation, payment failure, renewal, and usage quota warnings.
6. **Flutter Client Services & Screens**:
   - `billing_service.dart`, `admin_service.dart`
   - `billing_provider.dart`, `admin_provider.dart`
   - Update `subscription_usage_screen.dart` to match Customer Billing Dashboard.
   - Update `super_admin_dashboard_screen.dart` to match Super Admin Control Panel with all 6 tiles.
7. **Verification & Testing**:
   - Pytest suite covering all billing endpoints, entitlements, Razorpay signature verification, refund checks, and Super Admin RBAC.
   - Flutter analyze (0 issues) and widget tests.

