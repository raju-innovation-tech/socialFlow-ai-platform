def test_create_and_get_workspace(client):
    payload = {
        "name": "SocialFlow Studio",
        "description": "Primary Agency Workspace",
    }
    response = client.post("/api/v1/workspaces", json=payload)
    assert response.status_code == 201
    created = response.json()
    assert created["name"] == "SocialFlow Studio"
    assert created["slug"] == "socialflow-studio"
    assert "id" in created

    ws_id = created["id"]

    # Fetch by ID
    get_res = client.get(f"/api/v1/workspaces/{ws_id}")
    assert get_res.status_code == 200
    assert get_res.json()["id"] == ws_id


def test_workspace_slug_conflict(client):
    payload = {
        "name": "Duplicate Team",
        "slug": "duplicate-team-slug",
    }
    res1 = client.post("/api/v1/workspaces", json=payload)
    assert res1.status_code == 201

    res2 = client.post("/api/v1/workspaces", json=payload)
    assert res2.status_code == 409
    assert "already exists" in res2.json()["message"]


def test_list_workspaces(client):
    res = client.get("/api/v1/workspaces")
    assert res.status_code == 200
    assert isinstance(res.json(), list)

