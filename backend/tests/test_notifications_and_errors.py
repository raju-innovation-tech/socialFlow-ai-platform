from app.models.notification import Notification
from app.models.user import User


def test_notifications_and_read_status(client, db_session, auth_headers):
    ws_id = auth_headers["workspace_id"]
    headers = auth_headers["headers"]

    user = User(email="alex@socialflow.ai", normalized_email="alex@socialflow.ai", full_name="Alex Rivera", hashed_password="pw")
    db_session.add(user)
    db_session.commit()

    # Seed notification
    notif = Notification(
        workspace_id=ws_id,
        user_id=user.id,
        title="Post Approved",
        message="Your post 'SocialFlow AI Launch' has been approved by Lead Editor.",
        notification_type="approval",
        is_read=False,
    )
    db_session.add(notif)
    db_session.commit()

    # List notifications
    list_res = client.get(f"/api/v1/notifications?workspace_id={ws_id}", headers=headers)
    assert list_res.status_code == 200
    assert len(list_res.json()) == 1

    # Get notification by ID (should mark is_read=True)
    get_res = client.get(f"/api/v1/notifications/{notif.id}", headers=headers)
    assert get_res.status_code == 200
    assert get_res.json()["is_read"] is True


def test_custom_exception_responses(client, auth_headers):
    headers = auth_headers["headers"]

    # 404 Not Found error response structure
    res_404 = client.get("/api/v1/workspaces/00000000-0000-0000-0000-000000000000", headers=headers)
    assert res_404.status_code == 404
    body = res_404.json()
    assert body["error_code"] == "RESOURCE_NOT_FOUND"
    assert "was not found" in body["message"]
    assert "request_id" in body
    assert "timestamp" in body

    # 422 Unprocessable Entity for invalid schema
    res_422 = client.post("/api/v1/workspaces", json={"name": ""}, headers=headers)  # min_length=2
    assert res_422.status_code == 422
    body_422 = res_422.json()
    assert body_422["error_code"] == "VALIDATION_ERROR"

