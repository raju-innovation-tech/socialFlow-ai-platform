import pytest
from unittest.mock import AsyncMock, patch
from datetime import datetime, timezone
import httpx

from app.models.social_account import IntegrationEvent, SocialAccount, SocialAccountPermission


def test_list_available_platforms(client):
    res = client.get("/api/v1/integrations/platforms")
    assert res.status_code == 200
    data = res.json()
    assert "platforms" in data
    assert len(data["platforms"]) == 7
    ids = [p["identifier"] for p in data["platforms"]]
    assert set(ids) == {"linkedin", "facebook", "instagram", "youtube", "x", "whatsapp", "telegram"}


def test_platform_capabilities_engine(client):
    # Test all capabilities
    res_all = client.get("/api/v1/integrations/capabilities")
    assert res_all.status_code == 200
    caps = res_all.json()
    assert len(caps) >= 20

    # Test single platform filter
    res_x = client.get("/api/v1/integrations/capabilities?platform=x")
    assert res_x.status_code == 200
    caps_x = res_x.json()
    assert any(c["code"] == "publish_tweet" and c["status"] == "supported" for c in caps_x)
    assert any(c["code"] == "free_tier_restrictions" and c["status"] == "restricted" for c in caps_x)

    # Test WhatsApp explicit restrictions
    res_wa = client.get("/api/v1/integrations/capabilities?platform=whatsapp")
    assert res_wa.status_code == 200
    caps_wa = res_wa.json()
    assert any(c["code"] == "whatsapp_channels" and c["status"] == "unavailable" for c in caps_wa)
    assert any(c["code"] == "whatsapp_groups" and c["status"] == "unavailable" for c in caps_wa)


def test_oauth_authorization_url_generation(client, auth_headers):
    headers = auth_headers["headers"]

    # LinkedIn
    res_li = client.get("/api/v1/integrations/linkedin/authorize", headers=headers)
    assert res_li.status_code == 200
    data_li = res_li.json()
    assert "linkedin.com/oauth/v2/authorization" in data_li["authorization_url"]
    assert "state=" in data_li["authorization_url"]

    # X with PKCE
    res_x = client.get("/api/v1/integrations/x/authorize", headers=headers)
    assert res_x.status_code == 200
    data_x = res_x.json()
    assert "code_challenge=" in data_x["authorization_url"]
    assert "code_challenge_method=S256" in data_x["authorization_url"]


def test_telegram_bot_connection_and_validation(client, auth_headers):
    headers = auth_headers["headers"]

    mock_get_me = {
        "ok": True,
        "result": {
            "id": 987654321,
            "is_bot": True,
            "first_name": "SocialFlow Bot",
            "username": "SocialFlowDemoBot",
        },
    }

    with patch.object(
        httpx.AsyncClient,
        "get",
        return_value=httpx.Response(200, json=mock_get_me, request=httpx.Request("GET", "https://test")),
    ):
        payload = {
            "bot_token": "123456789:ABCdefGhIJKlmNoPQRsTUVwxyZ",
            "chat_id": None,
        }
        res = client.post("/api/v1/integrations/telegram/connect-bot", json=payload, headers=headers)
        assert res.status_code == 200
        data = res.json()
        assert data["platform"] == "telegram"
        assert data["account_name"] == "SocialFlow Bot"
        assert data["platform_account_id"] == "987654321"


def test_whatsapp_webhook_verification_and_event_receiver(client, db_session):
    # 1. Challenge verification
    verify_url = (
        "/api/v1/integrations/whatsapp/webhook"
        "?hub.mode=subscribe"
        "&hub.verify_token=socialflow_whatsapp_webhook_verify_secret_2026"
        "&hub.challenge=115325236"
    )
    res_v = client.get(verify_url)
    assert res_v.status_code == 200
    assert res_v.text == "115325236"

    # Bad verify token rejected
    bad_v = client.get("/api/v1/integrations/whatsapp/webhook?hub.mode=subscribe&hub.verify_token=wrong&hub.challenge=123")
    assert bad_v.status_code == 403

    # 2. Ingest incoming delivery receipt webhook
    payload = {
        "object": "whatsapp_business_account",
        "entry": [
            {
                "id": "WABA_12345",
                "changes": [
                    {
                        "field": "messages",
                        "value": {
                            "statuses": [
                                {
                                    "id": "wamid.HBgL...",
                                    "status": "delivered",
                                    "timestamp": "1710400000",
                                    "recipient_id": "15551234567",
                                }
                            ]
                        },
                    }
                ],
            }
        ],
    }
    res_post = client.post("/api/v1/integrations/whatsapp/webhook", json=payload)
    assert res_post.status_code == 200
    assert res_post.json()["status"] == "event_received"

    # Verify event stored in DB
    event = db_session.query(IntegrationEvent).filter(
        IntegrationEvent.platform == "whatsapp",
        IntegrationEvent.event_type == "cloud_api_webhook",
    ).first()
    assert event is not None
    assert "wamid.HBgL" in event.payload_json


def test_oauth_callback_and_tenant_isolation(client, auth_headers):
    headers = auth_headers["headers"]
    ws_id = auth_headers["workspace_id"]

    # 1. Generate auth flow
    res_auth = client.get("/api/v1/integrations/linkedin/authorize", headers=headers)
    state = res_auth.json()["state"]

    mock_token_resp = {
        "access_token": "fake_linkedin_access_token_12345",
        "expires_in": 5184000,
        "scope": "openid profile email w_member_social",
    }
    mock_userinfo_resp = {
        "sub": "li_member_998877",
        "name": "Sarah Connor",
        "email": "sarah.connor@cyberdyne.io",
        "picture": "https://media.licdn.com/dms/image/v2/fake.jpg",
    }

    # 2. Exchange code via callback
    with patch.object(
        httpx.AsyncClient,
        "post",
        return_value=httpx.Response(200, json=mock_token_resp, request=httpx.Request("POST", "https://test")),
    ), patch.object(
        httpx.AsyncClient,
        "get",
        return_value=httpx.Response(200, json=mock_userinfo_resp, request=httpx.Request("GET", "https://test")),
    ):
        cb_res = client.post(
            "/api/v1/integrations/linkedin/callback",
            json={"code": "auth_code_xyz", "state": state},
        )
        assert cb_res.status_code == 200
        cb_data = cb_res.json()
        assert cb_data["status"] == "success"
        account_id = cb_data["account_id"]

        # 3. Verify permissions endpoint
        perm_res = client.get(f"/api/v1/social-accounts/{account_id}/permissions", headers=headers)
        assert perm_res.status_code == 200
        perms = [p["scope"] for p in perm_res.json()]
        assert "w_member_social" in perms

        # 4. Verify sync endpoint
        with patch.object(
            httpx.AsyncClient,
            "get",
            return_value=httpx.Response(200, json=mock_userinfo_resp, request=httpx.Request("GET", "https://test")),
        ):
            sync_res = client.post(f"/api/v1/social-accounts/{account_id}/sync", headers=headers)
            assert sync_res.status_code == 200
            assert sync_res.json()["connection_status"] == "connected"

        # 5. Cross-Tenant Blocking: Another user in another workspace cannot access or sync this account
        client.post(
            "/api/v1/auth/register",
            json={"full_name": "Eve Other", "email": "eve.other@rival.com", "password": "Password123!", "confirm_password": "Password123!", "terms_accepted": True},
        )
        r2 = client.post("/api/v1/auth/resend-verification?email=eve.other@rival.com")
        client.post("/api/v1/auth/verify-email", json={"email": "eve.other@rival.com", "otp": r2.json()["dev_verification_otp"]})
        l2 = client.post("/api/v1/auth/login", json={"email": "eve.other@rival.com", "password": "Password123!"})
        headers_eve = {
            "Authorization": f"Bearer {l2.json()['access_token']}",
            "X-Workspace-ID": l2.json()["user"]["default_workspace_id"],
        }

        # Eve attempts to access Sarah's account
        blocked_get = client.get(f"/api/v1/social-accounts/{account_id}", headers=headers_eve)
        assert blocked_get.status_code == 403

        blocked_sync = client.post(f"/api/v1/social-accounts/{account_id}/sync", headers=headers_eve)
        assert blocked_sync.status_code == 404  # Not found in Eve's workspace
