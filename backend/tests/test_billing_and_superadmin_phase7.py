import hashlib
import hmac
from datetime import datetime, timezone
from decimal import Decimal
from app.core.config import settings
from app.core.security import create_access_token
from app.models.billing import Invoice, SubscriptionPlan, WorkspaceSubscription
from app.models.user import User
from app.models.workspace import Workspace


def test_customer_billing_flow(client, db_session, auth_headers):
    ws_id = auth_headers["workspace_id"]
    headers = auth_headers["headers"]

    # 1. List Plans
    res = client.get("/api/v1/billing/plans")
    assert res.status_code == 200
    plans = res.json()
    assert len(plans) >= 4
    plan_codes = [p["plan_code"] for p in plans]
    assert "free" in plan_codes
    assert "pro" in plan_codes

    # 2. Get Subscription & Usage
    sub_res = client.get(f"/api/v1/billing/subscription?workspace_id={ws_id}", headers=headers)
    assert sub_res.status_code == 200
    sub_data = sub_res.json()
    assert sub_data["status"] == "active"

    usage_res = client.get(f"/api/v1/billing/usage?workspace_id={ws_id}", headers=headers)
    assert usage_res.status_code == 200
    u_data = usage_res.json()
    assert "usage" in u_data
    assert "limits" in u_data
    assert "connected_accounts" in u_data["usage"]
    assert "monthly_publishing" in u_data["usage"]
    assert "team_members" in u_data["usage"]

    # 3. Create Checkout Order for Pro Plan
    checkout_res = client.post(
        f"/api/v1/billing/checkout?workspace_id={ws_id}",
        json={"plan_code": "pro", "billing_cycle": "monthly"},
        headers=headers,
    )
    assert checkout_res.status_code == 200
    chk_data = checkout_res.json()
    assert "order_id" in chk_data
    assert chk_data["plan_code"] == "pro"
    order_id = chk_data["order_id"]

    # 4. Verify Payment with Invalid Signature (Must Fail)
    fail_verify = client.post(
        f"/api/v1/billing/verify-payment?workspace_id={ws_id}",
        json={
            "order_id": order_id,
            "payment_id": "pay_fake_12345",
            "signature": "invalid_sig_abc",
            "plan_code": "pro",
            "billing_cycle": "monthly",
        },
        headers=headers,
    )
    assert fail_verify.status_code == 400

    # 5. Verify Payment with Genuine HMAC-SHA256 Signature (Must Succeed)
    payment_id = "pay_rzp_test_success_999"
    secret = getattr(settings, "RAZORPAY_KEY_SECRET", "mock_razorpay_secret")
    message = f"{order_id}|{payment_id}".encode("utf-8")
    valid_signature = hmac.new(secret.encode("utf-8"), message, hashlib.sha256).hexdigest()

    success_verify = client.post(
        f"/api/v1/billing/verify-payment?workspace_id={ws_id}",
        json={
            "order_id": order_id,
            "payment_id": payment_id,
            "signature": valid_signature,
            "plan_code": "pro",
            "billing_cycle": "monthly",
        },
        headers=headers,
    )
    assert success_verify.status_code == 200
    ver_data = success_verify.json()
    assert ver_data["status"] == "success"
    assert "invoice_number" in ver_data

    # 6. Check Invoices & Download
    inv_res = client.get(f"/api/v1/billing/invoices?workspace_id={ws_id}", headers=headers)
    assert inv_res.status_code == 200
    invoices = inv_res.json()
    assert len(invoices) >= 1
    inv_id = invoices[0]["id"]

    dl_res = client.get(f"/api/v1/billing/invoices/{inv_id}/download?workspace_id={ws_id}", headers=headers)
    assert dl_res.status_code == 200
    assert "SOCIALFLOW AI TAX INVOICE" in dl_res.text

    # 7. Cancel and Resume Subscription
    cancel_res = client.post(f"/api/v1/billing/subscription/cancel?workspace_id={ws_id}", headers=headers)
    assert cancel_res.status_code == 200
    assert cancel_res.json()["cancel_at_period_end"] is True

    resume_res = client.post(f"/api/v1/billing/subscription/resume?workspace_id={ws_id}", headers=headers)
    assert resume_res.status_code == 200
    assert resume_res.json()["cancel_at_period_end"] is False


def test_super_admin_security_and_operations(client, db_session, auth_headers):
    # 1. Normal Workspace User Accessing Super Admin API (Must be 403 Forbidden)
    norm_headers = auth_headers["headers"]
    f_res = client.get("/api/v1/admin/overview", headers=norm_headers)
    assert f_res.status_code == 403

    # 2. Provision Super Admin User
    admin_user = User(
        email="superadmin@socialflow.ai",
        normalized_email="superadmin@socialflow.ai",
        full_name="Platform Chief",
        hashed_password="pw",
        is_active=True,
        email_verified=True,
        is_super_admin=True,
    )
    db_session.add(admin_user)
    db_session.commit()

    admin_token = create_access_token(user_id=admin_user.id, email=admin_user.email, is_super_admin=True)
    admin_headers = {"Authorization": f"Bearer {admin_token}"}

    # 3. Super Admin Overview
    ov_res = client.get("/api/v1/admin/overview", headers=admin_headers)
    assert ov_res.status_code == 200
    ov = ov_res.json()
    assert "total_users" in ov
    assert "total_workspaces" in ov
    assert "mrr" in ov
    assert "arr" in ov

    # 4. List Users & Suspend / Reactivate
    u_res = client.get("/api/v1/admin/users", headers=admin_headers)
    assert u_res.status_code == 200
    target_user = db_session.query(User).filter(User.email == "engineer@socialflow.ai").first()

    susp_res = client.post(
        f"/api/v1/admin/users/{target_user.id}/suspend",
        json={"reason": "Suspicious login attempt"},
        headers=admin_headers,
    )
    assert susp_res.status_code == 200
    assert susp_res.json()["status"] == "suspended"

    react_res = client.post(f"/api/v1/admin/users/{target_user.id}/reactivate", headers=admin_headers)
    assert react_res.status_code == 200
    assert react_res.json()["status"] == "active"

    # 5. List Workspaces & Suspend / Reactivate
    ws_res = client.get("/api/v1/admin/workspaces", headers=admin_headers)
    assert ws_res.status_code == 200
    target_ws = db_session.query(Workspace).first()

    ws_susp = client.post(
        f"/api/v1/admin/workspaces/{target_ws.id}/suspend",
        json={"reason": "Policy check"},
        headers=admin_headers,
    )
    assert ws_susp.status_code == 200
    assert ws_susp.json()["status"] == "suspended"

    ws_react = client.post(f"/api/v1/admin/workspaces/{target_ws.id}/reactivate", headers=admin_headers)
    assert ws_react.status_code == 200
    assert ws_react.json()["status"] == "active"

    # 6. Admin Plan Management: Create Custom Plan
    p_res = client.post(
        "/api/v1/admin/plans",
        json={
            "plan_code": "agency_pro",
            "name": "Agency Pro Tier",
            "description": "Custom plan for marketing agencies",
            "price_monthly": 4999.00,
            "price_annual": 49990.00,
            "currency": "INR",
            "max_social_accounts": 30,
            "max_team_members": 10,
            "monthly_published_targets": 1000,
            "max_storage_mb": 50000,
            "analytics_history_days": 180,
            "export_enabled": True,
            "display_order": 5,
        },
        headers=admin_headers,
    )
    assert p_res.status_code == 201
    assert p_res.json()["plan_code"] == "agency_pro"

    # 7. Admin Payments & Refunds
    inv = Invoice(
        workspace_id=target_ws.id,
        invoice_number="INV-TEST-001",
        amount_paid=Decimal("2499.00"),
        subtotal_amount=Decimal("2117.80"),
        tax_amount=Decimal("381.20"),
        currency="INR",
        status="paid",
        payment_method="razorpay",
        provider_payment_id="pay_test_refund_target",
    )
    db_session.add(inv)
    db_session.commit()

    refund_res = client.post(
        "/api/v1/admin/refunds",
        json={"invoice_id": inv.id, "reason": "Customer cancellation within 7 days"},
        headers=admin_headers,
    )
    assert refund_res.status_code == 200
    rf = refund_res.json()
    assert rf["status"] == "success"
    assert "refund_id" in rf

    # Duplicate refund must fail
    dup_refund = client.post(
        "/api/v1/admin/refunds",
        json={"invoice_id": inv.id, "reason": "Second refund attempt"},
        headers=admin_headers,
    )
    assert dup_refund.status_code == 400

    # 8. Integration Health & Audit Logs
    ih_res = client.get("/api/v1/admin/integrations/health", headers=admin_headers)
    assert ih_res.status_code == 200
    assert len(ih_res.json()) == 7

    audit_res = client.get("/api/v1/admin/audit-logs", headers=admin_headers)
    assert audit_res.status_code == 200
    assert len(audit_res.json()) >= 1
