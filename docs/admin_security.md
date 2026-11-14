# SocialFlow AI – Admin Security & Audit Logging (Phase 7)

## 1. Protected Admin Authorization

All `/api/v1/admin/*` endpoints strictly require `Depends(get_current_super_admin)`. If an authenticated normal workspace user or admin attempts to call any admin endpoint, FastAPI immediately rejects the request with `403 Forbidden: Platform Super Admin privileges required`.

---

## 2. Immutable Platform Audit Logging

Administrative operations automatically record an entry into `audit_logs`:
- `actor_id`: User ID of the executing Super Admin.
- `entity_type`: Target entity (`user`, `workspace`, `subscription_plan`, `payment_refund`).
- `entity_id`: UUID of the affected entity.
- `action`: Administrative action code (`suspend_user`, `reactivate_user`, `suspend_workspace`, `issue_refund`, `create_plan`).
- `metadata_json`: Sanitized context and reason (no passwords or credentials).
- `logged_at`: UTC timestamp.

