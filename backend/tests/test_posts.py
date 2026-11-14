def test_post_lifecycle(client, auth_headers):
    ws_id = auth_headers["workspace_id"]
    headers = auth_headers["headers"]

    # 1. Create Draft Post with variants
    payload = {
        "workspace_id": ws_id,
        "title": "SocialFlow AI Launch Announcement",
        "content": "Excited to introduce SocialFlow AI - the unified social operating system!",
        "content_type": "text",
        "variants": [
            {
                "platform": "x",
                "customized_content": "Introducing SocialFlow AI! Multi-platform scheduling #AI #SaaS",
            },
            {
                "platform": "linkedin",
                "customized_content": "We are thrilled to announce SocialFlow AI. Streamlining content teams across 7 platforms.",
            },
        ],
    }
    create_res = client.post("/api/v1/posts", json=payload, headers=headers)
    assert create_res.status_code == 201
    post = create_res.json()
    assert post["status"] == "draft"
    assert post["title"] == "SocialFlow AI Launch Announcement"
    post_id = post["id"]

    # 2. Get Post
    get_res = client.get(f"/api/v1/posts/{post_id}", headers=headers)
    assert get_res.status_code == 200
    assert get_res.json()["id"] == post_id

    # 3. Update Post
    update_res = client.put(f"/api/v1/posts/{post_id}", json={"status": "scheduled"}, headers=headers)
    assert update_res.status_code == 200
    assert update_res.json()["status"] == "scheduled"

    # 4. List posts by workspace
    list_res = client.get(f"/api/v1/posts?workspace_id={ws_id}", headers=headers)
    assert list_res.status_code == 200
    assert len(list_res.json()) >= 1

    # 5. Delete post
    del_res = client.delete(f"/api/v1/posts/{post_id}", headers=headers)
    assert del_res.status_code == 204

