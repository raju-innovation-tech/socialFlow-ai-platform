def test_create_and_get_workspace(client, auth_headers):
    payload = {
        "name": "SocialFlow Studio",
        "description": "Primary Agency Workspace",
    }
    response = client.post("/api/v1/workspaces", json=payload, headers=auth_headers["headers"])
    assert response.status_code == 201
    created = response.json()
    assert created["name"] == "SocialFlow Studio"
    assert created["slug"] == "socialflow-studio"
    assert "id" in created

    ws_id = created["id"]

    # Fetch by ID
    get_res = client.get(f"/api/v1/workspaces/{ws_id}", headers=auth_headers["headers"])
    assert get_res.status_code == 200
    assert get_res.json()["id"] == ws_id


def test_workspace_slug_conflict(client, auth_headers):
    payload = {
        "name": "Duplicate Team",
        "slug": "duplicate-team-slug",
    }
    res1 = client.post("/api/v1/workspaces", json=payload, headers=auth_headers["headers"])
    assert res1.status_code == 201

    res2 = client.post("/api/v1/workspaces", json=payload, headers=auth_headers["headers"])
    assert res2.status_code == 409
    assert "already exists" in res2.json()["message"]


def test_list_workspaces(client, auth_headers):
    res = client.get("/api/v1/workspaces", headers=auth_headers["headers"])
    assert res.status_code == 200
    assert isinstance(res.json(), list)
    assert len(res.json()) >= 1

