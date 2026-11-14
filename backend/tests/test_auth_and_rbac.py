import pytest
from app.core.security import hash_password
from app.models.user import User


def test_user_registration_and_otp_verification(client):
    # 1. Register new user
    reg_payload = {
        "full_name": "Elena Rostova",
        "email": "Elena.Rostova@SocialFlow.AI ",  # Test trimming and case-normalization
        "password": "SecurePassword123!",
        "confirm_password": "SecurePassword123!",
        "terms_accepted": True,
    }
    reg_res = client.post("/api/v1/auth/register", json=reg_payload)
    assert reg_res.status_code == 201
    reg_data = reg_res.json()
    assert "user_id" in reg_data
    assert "dev_verification_otp" in reg_data
    otp_code = reg_data["dev_verification_otp"]

    # 2. Duplicate registration should be rejected with 409
    dup_res = client.post("/api/v1/auth/register", json=reg_payload)
    assert dup_res.status_code == 409

    # 3. Attempt login before verification should be blocked
    login_unverified = client.post(
        "/api/v1/auth/login",
        json={"email": "elena.rostova@socialflow.ai", "password": "SecurePassword123!"},
    )
    assert login_unverified.status_code == 403
    assert "not verified" in login_unverified.json()["message"]

    # 4. Verify email with wrong OTP code
    bad_otp_res = client.post(
        "/api/v1/auth/verify-email",
        json={"email": "elena.rostova@socialflow.ai", "otp": "000000"},
    )
    assert bad_otp_res.status_code == 400

    # 5. Verify email with valid OTP
    good_otp_res = client.post(
        "/api/v1/auth/verify-email",
        json={"email": "elena.rostova@socialflow.ai", "otp": otp_code},
    )
    assert good_otp_res.status_code == 200

    # 6. Login now succeeds
    login_res = client.post(
        "/api/v1/auth/login",
        json={"email": "elena.rostova@socialflow.ai", "password": "SecurePassword123!"},
    )
    assert login_res.status_code == 200
    login_data = login_res.json()
    assert "access_token" in login_data
    assert "refresh_token" in login_data
    assert login_data["user"]["email"].lower() == "elena.rostova@socialflow.ai"
    assert login_data["user"]["default_workspace_id"] is not None


def test_refresh_token_rotation_and_theft_detection(client):
    # Setup verified user
    client.post(
        "/api/v1/auth/register",
        json={
            "full_name": "Marcus Vance",
            "email": "marcus@socialflow.ai",
            "password": "Password123!",
            "confirm_password": "Password123!",
            "terms_accepted": True,
        },
    )
    # Fetch OTP from db or resend
    resend = client.post("/api/v1/auth/resend-verification?email=marcus@socialflow.ai")
    otp = resend.json()["dev_verification_otp"]
    client.post("/api/v1/auth/verify-email", json={"email": "marcus@socialflow.ai", "otp": otp})

    # Login
    login_res = client.post(
        "/api/v1/auth/login",
        json={"email": "marcus@socialflow.ai", "password": "Password123!"},
    )
    assert login_res.status_code == 200
    token1 = login_res.json()["refresh_token"]

    # 1. Rotate token
    rotate_res = client.post("/api/v1/auth/refresh", json={"refresh_token": token1})
    assert rotate_res.status_code == 200
    token2 = rotate_res.json()["refresh_token"]
    assert token2 != token1

    # 2. Token reuse detection: Replaying token1 must fail and trigger family revocation
    replay_res = client.post("/api/v1/auth/refresh", json={"refresh_token": token1})
    assert replay_res.status_code == 401
    assert "reuse detected" in replay_res.json()["message"]

    # 3. Even token2 should now be revoked due to family theft invalidation
    subsequent_res = client.post("/api/v1/auth/refresh", json={"refresh_token": token2})
    assert subsequent_res.status_code == 401


def test_multi_tenancy_and_workspace_switching(client):
    # Register User A (Alice)
    client.post(
        "/api/v1/auth/register",
        json={
            "full_name": "Alice Cooper",
            "email": "alice@tenant.com",
            "password": "Password123!",
            "confirm_password": "Password123!",
            "terms_accepted": True,
        },
    )
    resend_a = client.post("/api/v1/auth/resend-verification?email=alice@tenant.com")
    client.post("/api/v1/auth/verify-email", json={"email": "alice@tenant.com", "otp": resend_a.json()["dev_verification_otp"]})
    login_a = client.post("/api/v1/auth/login", json={"email": "alice@tenant.com", "password": "Password123!"})
    access_token_a = login_a.json()["access_token"]
    headers_a = {"Authorization": f"Bearer {access_token_a}"}

    # Alice creates a second workspace
    ws2_res = client.post(
        "/api/v1/workspaces",
        json={"name": "Alice Growth Lab"},
        headers=headers_a,
    )
    assert ws2_res.status_code == 201
    ws2_id = ws2_res.json()["id"]

    # Alice lists workspaces (should see 2 workspaces)
    list_ws = client.get("/api/v1/workspaces", headers=headers_a)
    assert list_ws.status_code == 200
    assert len(list_ws.json()) == 2

    # Alice switches active workspace context
    switch_res = client.post(f"/api/v1/workspaces/{ws2_id}/switch", headers=headers_a)
    assert switch_res.status_code == 200
    switch_data = switch_res.json()
    assert switch_data["role"] == "owner"
    assert "posts.create" in switch_data["permissions"]


def test_tenant_isolation_cross_workspace_blocking(client):
    # User 1: Bob (Acme Corp)
    client.post(
        "/api/v1/auth/register",
        json={"full_name": "Bob Acme", "email": "bob@acme.com", "password": "Password123!", "confirm_password": "Password123!", "terms_accepted": True},
    )
    r1 = client.post("/api/v1/auth/resend-verification?email=bob@acme.com")
    client.post("/api/v1/auth/verify-email", json={"email": "bob@acme.com", "otp": r1.json()["dev_verification_otp"]})
    l1 = client.post("/api/v1/auth/login", json={"email": "bob@acme.com", "password": "Password123!"})
    token_bob = l1.json()["access_token"]
    ws_bob = l1.json()["user"]["default_workspace_id"]
    headers_bob = {"Authorization": f"Bearer {token_bob}", "X-Workspace-ID": ws_bob}

    # Bob creates a post in Acme workspace
    bob_post = client.post(
        "/api/v1/posts",
        json={"workspace_id": ws_bob, "title": "Acme Confidential Post", "content": "Internal secret roadmap"},
        headers=headers_bob,
    )
    assert bob_post.status_code == 201
    bob_post_id = bob_post.json()["id"]

    # User 2: Eve (Evil Corp)
    client.post(
        "/api/v1/auth/register",
        json={"full_name": "Eve Hacker", "email": "eve@evil.com", "password": "Password123!", "confirm_password": "Password123!", "terms_accepted": True},
    )
    r2 = client.post("/api/v1/auth/resend-verification?email=eve@evil.com")
    client.post("/api/v1/auth/verify-email", json={"email": "eve@evil.com", "otp": r2.json()["dev_verification_otp"]})
    l2 = client.post("/api/v1/auth/login", json={"email": "eve@evil.com", "password": "Password123!"})
    token_eve = l2.json()["access_token"]
    ws_eve = l2.json()["user"]["default_workspace_id"]
    headers_eve = {"Authorization": f"Bearer {token_eve}", "X-Workspace-ID": ws_eve}

    # 1. Eve tries to query Bob's workspace directly -> BLOCKED (403 Forbidden)
    eve_hack_ws = client.get("/api/v1/posts", headers={"Authorization": f"Bearer {token_eve}", "X-Workspace-ID": ws_bob})
    assert eve_hack_ws.status_code == 403

    # 2. Eve tries to fetch Bob's post with her own workspace context (IDOR) -> BLOCKED (403 Forbidden)
    eve_hack_post = client.get(f"/api/v1/posts/{bob_post_id}", headers=headers_eve)
    assert eve_hack_post.status_code == 403
    assert "Cross-tenant access prohibited" in eve_hack_post.json()["message"]


def test_workspace_invitations_and_rbac(client):
    # Setup Owner (Sarah)
    client.post(
        "/api/v1/auth/register",
        json={"full_name": "Sarah Connor", "email": "sarah@skynet.com", "password": "Password123!", "confirm_password": "Password123!", "terms_accepted": True},
    )
    r_s = client.post("/api/v1/auth/resend-verification?email=sarah@skynet.com")
    client.post("/api/v1/auth/verify-email", json={"email": "sarah@skynet.com", "otp": r_s.json()["dev_verification_otp"]})
    l_s = client.post("/api/v1/auth/login", json={"email": "sarah@skynet.com", "password": "Password123!"})
    token_sarah = l_s.json()["access_token"]
    ws_id = l_s.json()["user"]["default_workspace_id"]
    headers_sarah = {"Authorization": f"Bearer {token_sarah}", "X-Workspace-ID": ws_id}

    # Sarah invites John as a Viewer
    invite_res = client.post(
        f"/api/v1/workspaces/{ws_id}/invitations",
        json={"email": "john@skynet.com", "role": "viewer"},
        headers=headers_sarah,
    )
    assert invite_res.status_code == 201
    invite_token = invite_res.json()["dev_invitation_token"]

    # Register John
    client.post(
        "/api/v1/auth/register",
        json={"full_name": "John Connor", "email": "john@skynet.com", "password": "Password123!", "confirm_password": "Password123!", "terms_accepted": True},
    )
    r_j = client.post("/api/v1/auth/resend-verification?email=john@skynet.com")
    client.post("/api/v1/auth/verify-email", json={"email": "john@skynet.com", "otp": r_j.json()["dev_verification_otp"]})
    l_j = client.post("/api/v1/auth/login", json={"email": "john@skynet.com", "password": "Password123!"})
    token_john = l_j.json()["access_token"]

    # John accepts invitation
    accept_res = client.post(
        "/api/v1/invitations/accept",
        json={"token": invite_token},
        headers={"Authorization": f"Bearer {token_john}"},
    )
    assert accept_res.status_code == 200
    assert accept_res.json()["role"] == "viewer"

    # John (Viewer) tries to CREATE a post in the workspace -> BLOCKED by RBAC (403 Forbidden)
    headers_john = {"Authorization": f"Bearer {token_john}", "X-Workspace-ID": ws_id}
    john_create = client.post(
        "/api/v1/posts",
        json={"title": "Viewer Post", "content": "Can I publish?"},
        headers=headers_john,
    )
    assert john_create.status_code == 403
    assert "lacks the required permission" in john_create.json()["message"]


def test_super_admin_protection(client, db_session):
    # Regular user cannot access /api/v1/admin/users
    client.post(
        "/api/v1/auth/register",
        json={"full_name": "Normal Joe", "email": "joe@normal.com", "password": "Password123!", "confirm_password": "Password123!", "terms_accepted": True},
    )
    r = client.post("/api/v1/auth/resend-verification?email=joe@normal.com")
    client.post("/api/v1/auth/verify-email", json={"email": "joe@normal.com", "otp": r.json()["dev_verification_otp"]})
    l = client.post("/api/v1/auth/login", json={"email": "joe@normal.com", "password": "Password123!"})
    normal_headers = {"Authorization": f"Bearer {l.json()['access_token']}"}

    forbidden_admin = client.get("/api/v1/admin/users", headers=normal_headers)
    assert forbidden_admin.status_code == 403

    # Provision Super Admin directly in DB (as required by security policy)
    user = db_session.query(User).filter(User.email == "joe@normal.com").first()
    user.is_super_admin = True
    db_session.commit()

    # Re-login to get updated JWT with is_super_admin=True
    l_admin = client.post("/api/v1/auth/login", json={"email": "joe@normal.com", "password": "Password123!"})
    admin_headers = {"Authorization": f"Bearer {l_admin.json()['access_token']}"}

    allowed_admin = client.get("/api/v1/admin/users", headers=admin_headers)
    assert allowed_admin.status_code == 200
    assert len(allowed_admin.json()) >= 1

