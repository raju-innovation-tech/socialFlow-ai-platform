from app.core.security import credential_vault
from app.models.social_account import SocialAccountCredential


def test_connect_and_list_social_account(client, db_session, auth_headers):
    ws_id = auth_headers["workspace_id"]
    headers = auth_headers["headers"]

    # Connect social account with sensitive access token
    plain_token = "secret_oauth_access_token_xyz_12345"
    payload = {
        "workspace_id": ws_id,
        "platform": "linkedin",
        "account_name": "SocialFlow Tech Page",
        "platform_account_id": "urn:li:organization:123456",
        "account_type": "page",
        "access_token": plain_token,
    }
    connect_res = client.post("/api/v1/social-accounts", json=payload, headers=headers)
    assert connect_res.status_code == 201
    account_data = connect_res.json()
    assert account_data["platform"] == "linkedin"
    assert account_data["account_name"] == "SocialFlow Tech Page"
    account_id = account_data["id"]

    # Verify credentials stored in DB are ENCRYPTED (never plain text)
    cred = db_session.query(SocialAccountCredential).filter(
        SocialAccountCredential.account_id == account_id
    ).first()
    assert cred is not None
    assert cred.encrypted_access_token != plain_token
    # Decrypt should restore original token
    assert credential_vault.decrypt(cred.encrypted_access_token) == plain_token

    # List accounts for workspace
    list_res = client.get(f"/api/v1/social-accounts?workspace_id={ws_id}", headers=headers)
    assert list_res.status_code == 200
    assert len(list_res.json()) >= 1

    # Disconnect account
    del_res = client.delete(f"/api/v1/social-accounts/{account_id}", headers=headers)
    assert del_res.status_code == 204

    # Verify deleted
    get_res = client.get(f"/api/v1/social-accounts/{account_id}", headers=headers)
    assert get_res.status_code == 404

