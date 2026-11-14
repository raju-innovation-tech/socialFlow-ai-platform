from datetime import datetime, timezone
from app.models.analytics import AnalyticsSnapshot, PostMetric
from app.models.notification import Notification, NotificationPreference
from app.models.post import Post, PostTarget
from app.models.social_account import SocialAccount
from app.models.user import User


def test_analytics_endpoints_and_calculations(client, db_session, auth_headers):
    ws_id = auth_headers["workspace_id"]
    headers = auth_headers["headers"]
    user = db_session.query(User).filter(User.email == "engineer@socialflow.ai").first()

    # 1. Seed connected social accounts
    ig_acc = SocialAccount(
        workspace_id=ws_id,
        platform="instagram",
        platform_account_id="ig_12345",
        account_name="socialflow_ig",
        follower_count=5200,
        connection_status="connected",
    )
    li_acc = SocialAccount(
        workspace_id=ws_id,
        platform="linkedin",
        platform_account_id="li_67890",
        account_name="socialflow_li",
        follower_count=3100,
        connection_status="connected",
    )
    db_session.add_all([ig_acc, li_acc])
    db_session.commit()

    # 2. Test Overview endpoint
    res = client.get(f"/api/v1/analytics/overview?period=last_7_days&workspace_id={ws_id}", headers=headers)
    assert res.status_code == 200
    data = res.json()
    assert data["total_accounts"] >= 2
    assert data["total_followers"] >= 8300
    assert "publishing_success_rate" in data
    assert "daily_performance" in data
    assert len(data["daily_performance"]) == 7

    # 3. Test Platform Analytics endpoint
    p_res = client.get(f"/api/v1/analytics/platforms?workspace_id={ws_id}", headers=headers)
    assert p_res.status_code == 200
    p_data = p_res.json()
    assert len(p_data["platforms"]) == 7
    platforms_map = {p["platform"]: p for p in p_data["platforms"]}
    assert platforms_map["instagram"]["followers"] >= 5200
    assert platforms_map["linkedin"]["followers"] >= 3100

    # 4. Test Single Account Analytics endpoint
    acc_res = client.get(f"/api/v1/analytics/accounts/{ig_acc.id}?workspace_id={ws_id}", headers=headers)
    assert acc_res.status_code == 200
    acc_data = acc_res.json()
    assert acc_data["account_id"] == ig_acc.id
    assert acc_data["platform"] == "instagram"
    assert acc_data["followers_count"] == 5200

    # 5. Test Post Analytics endpoint
    post = Post(
        workspace_id=ws_id,
        created_by_user_id=user.id,
        title="Q4 Performance Post",
        content="Our biggest update yet!",
        status="published",
    )
    db_session.add(post)
    db_session.commit()

    target = PostTarget(
        post_id=post.id,
        social_account_id=ig_acc.id,
        status="published",
        external_post_id="ext_ig_12345",
    )
    db_session.add(target)

    metric = PostMetric(
        post_id=post.id,
        social_account_id=ig_acc.id,
        recorded_at=datetime.now(timezone.utc),
        impressions=1200,
        reach=950,
        likes=85,
        comments=12,
        shares=4,
        clicks=25,
    )
    db_session.add(metric)
    db_session.commit()

    post_res = client.get(f"/api/v1/analytics/posts/{post.id}?workspace_id={ws_id}", headers=headers)
    assert post_res.status_code == 200
    post_data = post_res.json()
    assert post_data["post_id"] == post.id
    assert len(post_data["targets"]) == 1
    assert post_data["targets"][0]["likes"] == 85

    # 6. Test CSV Export endpoint
    csv_res = client.post(f"/api/v1/analytics/reports/export?workspace_id={ws_id}", headers=headers)
    assert csv_res.status_code == 200
    assert "text/csv" in csv_res.headers["content-type"]
    assert "SocialFlow AI - Analytics Performance Report" in csv_res.text
    assert "Instagram" in csv_res.text

    # 7. Test Manual Sync endpoint
    sync_res = client.post(f"/api/v1/analytics/sync?workspace_id={ws_id}", headers=headers)
    assert sync_res.status_code == 200
    assert sync_res.json()["status"] == "success"


def test_notifications_lifecycle_and_preferences(client, db_session, auth_headers):
    ws_id = auth_headers["workspace_id"]
    headers = auth_headers["headers"]
    user = db_session.query(User).filter(User.email == "engineer@socialflow.ai").first()

    # 1. Seed in-app notifications
    n1 = Notification(
        workspace_id=ws_id,
        user_id=user.id,
        title="Post successfully published",
        message="Your post 'Product Launch' was published to LinkedIn.",
        notification_type="publishing",
        is_read=False,
    )
    n2 = Notification(
        workspace_id=ws_id,
        user_id=user.id,
        title="Instagram authorization expired",
        message="Please reconnect Instagram account to continue.",
        notification_type="account",
        is_read=False,
    )
    db_session.add_all([n1, n2])
    db_session.commit()

    # 2. Check unread count
    count_res = client.get(f"/api/v1/notifications/unread-count?workspace_id={ws_id}", headers=headers)
    assert count_res.status_code == 200
    assert count_res.json()["unread_count"] == 2

    # 3. Mark single notification as read via PATCH
    patch_res = client.patch(f"/api/v1/notifications/{n1.id}/read?workspace_id={ws_id}", headers=headers)
    assert patch_res.status_code == 200
    assert patch_res.json()["is_read"] is True

    # 4. Check unread count decreased
    count_res2 = client.get(f"/api/v1/notifications/unread-count?workspace_id={ws_id}", headers=headers)
    assert count_res2.json()["unread_count"] == 1

    # 5. Mark all as read
    read_all_res = client.post(f"/api/v1/notifications/read-all?workspace_id={ws_id}", headers=headers)
    assert read_all_res.status_code == 200
    assert read_all_res.json()["updated"] == 1

    # 6. Verify count is 0
    count_res3 = client.get(f"/api/v1/notifications/unread-count?workspace_id={ws_id}", headers=headers)
    assert count_res3.json()["unread_count"] == 0

    # 7. Delete notification
    del_res = client.delete(f"/api/v1/notifications/{n1.id}?workspace_id={ws_id}", headers=headers)
    assert del_res.status_code == 204

    # 8. Notification Preferences
    pref_res = client.get(f"/api/v1/notifications/preferences?workspace_id={ws_id}", headers=headers)
    assert pref_res.status_code == 200
    prefs = pref_res.json()
    assert len(prefs) >= 5

    # Update preference
    update_res = client.patch(
        f"/api/v1/notifications/preferences?workspace_id={ws_id}",
        json={"channel": "email", "category": "publishing", "is_enabled": False},
        headers=headers,
    )
    assert update_res.status_code == 200
    assert update_res.json()["is_enabled"] is False

    # 9. Register device push token
    dev_res = client.post(
        f"/api/v1/notifications/devices/register?workspace_id={ws_id}",
        json={"device_token": "fcm_dummy_token_abc_123", "device_type": "android"},
        headers=headers,
    )
    assert dev_res.status_code == 200
    assert dev_res.json()["status"] == "registered"
