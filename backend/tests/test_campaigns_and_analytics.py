def test_campaign_and_analytics(client):
    ws_res = client.post("/api/v1/workspaces", json={"name": "Campaign Workspace"})
    ws_id = ws_res.json()["id"]

    # 1. Create Campaign
    c_res = client.post(
        "/api/v1/campaigns",
        json={
            "workspace_id": ws_id,
            "name": "Q4 Cyber Monday Blitz",
            "description": "Multi-channel promotion across IG, YouTube and LinkedIn",
            "budget_amount": 5000.00,
        },
    )
    assert c_res.status_code == 201
    campaign = c_res.json()
    assert campaign["name"] == "Q4 Cyber Monday Blitz"
    c_id = campaign["id"]

    # 2. Get Campaign
    get_res = client.get(f"/api/v1/campaigns/{c_id}")
    assert get_res.status_code == 200

    # 3. Analytics Overview
    overview_res = client.get(f"/api/v1/analytics/overview?workspace_id={ws_id}")
    assert overview_res.status_code == 200
    overview_data = overview_res.json()
    assert "total_engagement" in overview_data
    assert "daily_performance" in overview_data

    # 4. Platform Analytics
    platform_res = client.get(f"/api/v1/analytics/platforms?workspace_id={ws_id}")
    assert platform_res.status_code == 200
    p_data = platform_res.json()
    assert "platforms" in p_data
    assert len(p_data["platforms"]) >= 7

