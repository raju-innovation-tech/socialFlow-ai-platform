from datetime import datetime, timedelta, timezone
from unittest.mock import AsyncMock, patch
import httpx
import pytest

from app.integrations.base.token_manager import TokenManager
from app.models.media import MediaAsset
from app.models.post import Post, PostMedia, PostTarget
from app.models.publishing import PublishingJob
from app.models.social_account import SocialAccount
from app.publishing.services.retry_service import RetryService
from app.publishing.services.scheduling_service import SchedulingService
from app.publishing.workers.publishing_worker import PublishingWorker


@pytest.fixture
def sample_social_accounts(db_session, auth_headers):
    ws_id = auth_headers["workspace_id"]
    accounts = []
    platforms = ["linkedin", "facebook", "instagram", "youtube", "x", "whatsapp", "telegram"]

    for plat in platforms:
        acc = SocialAccount(
            workspace_id=ws_id,
            platform=plat,
            account_name=f"Test {plat.capitalize()} Account",
            platform_account_id=f"{plat}_12345",
            account_type="page" if plat in ("facebook", "linkedin") else "profile",
            connection_status="connected",
        )
        db_session.add(acc)
        db_session.flush()

        # Store test credentials
        TokenManager.encrypt_and_store(
            db=db_session,
            account_id=acc.id,
            access_token=f"valid_test_token_for_{plat}",
        )
        accounts.append(acc)

    db_session.commit()
    return accounts


def test_post_creation_with_variants_and_targets(client, auth_headers, sample_social_accounts):
    headers = auth_headers["headers"]
    acc_ids = [acc.id for acc in sample_social_accounts[:3]]

    payload = {
        "title": "Major Product Launch Announcement",
        "content": "Excited to introduce SocialFlow AI to the community! Check it out.",
        "content_type": "text",
        "workspace_id": auth_headers["workspace_id"],
        "target_account_ids": acc_ids,
        "variants": [
            {
                "platform": "x",
                "customized_content": "Excited to announce @SocialFlowAI launch! 🚀 #SaaS",
            },
            {
                "platform": "linkedin",
                "customized_content": "We are thrilled to announce SocialFlow AI. A unified social operations hub.",
            },
        ],
    }

    res = client.post("/api/v1/posts", json=payload, headers=headers)
    assert res.status_code == 201
    post_data = res.json()
    assert post_data["title"] == payload["title"]
    assert post_data["status"] == "draft"
    post_id = post_data["id"]

    # Verify detail endpoint
    detail_res = client.get(f"/api/v1/posts/{post_id}", headers=headers)
    assert detail_res.status_code == 200
    detail_data = detail_res.json()
    assert len(detail_data["targets"]) == 3
    assert len(detail_data["variants"]) == 2


def test_multi_platform_content_validation(client, auth_headers):
    headers = auth_headers["headers"]

    # Test X length limit violation (> 280 chars)
    long_tweet = "A" * 350
    val_payload = {
        "content": "Standard short text for all platforms.",
        "platforms": ["x", "linkedin", "facebook"],
        "variants": {
            "x": long_tweet,
        },
    }

    res = client.post("/api/v1/posts/validate", json=val_payload, headers=headers)
    assert res.status_code == 200
    data = res.json()
    assert data["x"]["is_valid"] is False
    assert any("280" in err for err in data["x"]["errors"])
    assert data["linkedin"]["is_valid"] is True
    assert data["facebook"]["is_valid"] is True


@pytest.mark.asyncio
async def test_immediate_publishing_orchestration(client, auth_headers, sample_social_accounts):
    headers = auth_headers["headers"]
    acc_ids = [acc.id for acc in sample_social_accounts[:2]]  # LinkedIn & Facebook

    # 1. Create a post
    payload = {
        "title": "Immediate Publish Post",
        "content": "Live announcement broadcast across channels.",
        "workspace_id": auth_headers["workspace_id"],
        "target_account_ids": acc_ids,
    }
    create_res = client.post("/api/v1/posts", json=payload, headers=headers)
    assert create_res.status_code == 201
    post_id = create_res.json()["id"]

    # Mock external platform HTTP responses
    mock_li_response = httpx.Response(201, json={"id": "urn:li:share:987654321"})
    mock_fb_response = httpx.Response(200, json={"id": "fb_page_post_112233"})

    with patch.object(httpx.AsyncClient, "post") as mock_post:
        mock_post.side_effect = [mock_li_response, mock_fb_response]

        pub_res = client.post(f"/api/v1/posts/{post_id}/publish", headers=headers)
        assert pub_res.status_code == 200
        pub_data = pub_res.json()
        assert pub_data["overall_status"] == "published"
        assert pub_data["success_count"] == 2
        assert pub_data["failure_count"] == 0

    # Verify status endpoint reflects published
    status_res = client.get(f"/api/v1/posts/{post_id}/publishing-status", headers=headers)
    assert status_res.status_code == 200
    status_data = status_res.json()
    assert status_data["status"] == "published"
    assert all(t["status"] == "published" for t in status_data["targets"])


def test_scheduling_future_post_and_utc_normalization(client, auth_headers, sample_social_accounts):
    headers = auth_headers["headers"]
    acc_id = sample_social_accounts[0].id

    # Create draft post
    create_res = client.post(
        "/api/v1/posts",
        json={
            "title": "Scheduled Post",
            "content": "Future publication test content.",
            "workspace_id": auth_headers["workspace_id"],
            "target_account_ids": [acc_id],
        },
        headers=headers,
    )
    post_id = create_res.json()["id"]

    future_time = datetime.now(timezone.utc) + timedelta(hours=3)
    sched_payload = {
        "scheduled_at": future_time.isoformat(),
        "timezone": "America/New_York",
    }

    sched_res = client.post(f"/api/v1/posts/{post_id}/schedule", json=sched_payload, headers=headers)
    assert sched_res.status_code == 200
    sched_data = sched_res.json()
    assert sched_data["status"] == "scheduled"
    assert sched_data["scheduled_at"] is not None


def test_scheduling_in_past_rejected(client, auth_headers, sample_social_accounts):
    headers = auth_headers["headers"]
    acc_id = sample_social_accounts[0].id

    create_res = client.post(
        "/api/v1/posts",
        json={
            "content": "Past schedule test.",
            "workspace_id": auth_headers["workspace_id"],
            "target_account_ids": [acc_id],
        },
        headers=headers,
    )
    post_id = create_res.json()["id"]

    past_time = datetime.now(timezone.utc) - timedelta(hours=2)
    bad_res = client.post(
        f"/api/v1/posts/{post_id}/schedule",
        json={"scheduled_at": past_time.isoformat(), "timezone": "UTC"},
        headers=headers,
    )
    assert bad_res.status_code == 400
    assert "future" in bad_res.json()["message"]


def test_cancel_scheduled_post(client, auth_headers, sample_social_accounts):
    headers = auth_headers["headers"]
    acc_id = sample_social_accounts[0].id

    create_res = client.post(
        "/api/v1/posts",
        json={
            "content": "Will be cancelled.",
            "workspace_id": auth_headers["workspace_id"],
            "target_account_ids": [acc_id],
        },
        headers=headers,
    )
    post_id = create_res.json()["id"]

    future_time = datetime.now(timezone.utc) + timedelta(hours=5)
    client.post(f"/api/v1/posts/{post_id}/schedule", json={"scheduled_at": future_time.isoformat()}, headers=headers)

    cancel_res = client.post(f"/api/v1/posts/{post_id}/cancel", headers=headers)
    assert cancel_res.status_code == 200
    assert cancel_res.json()["status"] == "draft"


def test_duplicate_post_to_draft(client, auth_headers, sample_social_accounts):
    headers = auth_headers["headers"]
    acc_id = sample_social_accounts[0].id

    create_res = client.post(
        "/api/v1/posts",
        json={
            "title": "Original Template",
            "content": "Content to duplicate.",
            "workspace_id": auth_headers["workspace_id"],
            "target_account_ids": [acc_id],
        },
        headers=headers,
    )
    post_id = create_res.json()["id"]

    dup_res = client.post(f"/api/v1/posts/{post_id}/duplicate", headers=headers)
    assert dup_res.status_code == 201
    dup_data = dup_res.json()
    assert dup_data["id"] != post_id
    assert "Copy" in dup_data["title"]
    assert dup_data["status"] == "draft"


def test_calendar_and_queue_endpoints(client, auth_headers, sample_social_accounts):
    headers = auth_headers["headers"]
    acc_id = sample_social_accounts[0].id

    # Create & schedule post
    create_res = client.post(
        "/api/v1/posts",
        json={
            "title": "Calendar Item",
            "content": "Item on the publishing queue.",
            "workspace_id": auth_headers["workspace_id"],
            "target_account_ids": [acc_id],
        },
        headers=headers,
    )
    post_id = create_res.json()["id"]

    future_time = datetime.now(timezone.utc) + timedelta(hours=2)
    client.post(f"/api/v1/posts/{post_id}/schedule", json={"scheduled_at": future_time.isoformat()}, headers=headers)

    # Check calendar endpoint
    cal_res = client.get("/api/v1/publishing/calendar", headers=headers)
    assert cal_res.status_code == 200
    cal_events = cal_res.json()
    assert any(e["id"] == post_id for e in cal_events)

    # Check queue endpoint
    q_res = client.get("/api/v1/publishing/queue", headers=headers)
    assert q_res.status_code == 200
    q_items = q_res.json()
    assert any(i["post_id"] == post_id for i in q_items)


def test_retry_service_exponential_backoff():
    # Attempt 1
    t1 = RetryService.calculate_next_retry(1, base_delay=10, max_delay=100)
    # Attempt 2
    t2 = RetryService.calculate_next_retry(2, base_delay=10, max_delay=100)
    # Attempt 3
    t3 = RetryService.calculate_next_retry(3, base_delay=10, max_delay=100)

    assert t1 < t2 < t3
    assert RetryService.is_eligible_for_retry(1, max_retries=3) is True
    assert RetryService.is_eligible_for_retry(3, max_retries=3) is False

