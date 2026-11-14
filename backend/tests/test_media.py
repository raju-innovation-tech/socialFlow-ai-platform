import io
import os


def test_media_upload_and_validation(client, auth_headers):
    ws_id = auth_headers["workspace_id"]
    headers = auth_headers["headers"]

    # 1. Valid image upload
    fake_png = b"\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x06\x00\x00\x00"
    files = {"file": ("banner.png", io.BytesIO(fake_png), "image/png")}
    data = {"workspace_id": ws_id}

    upload_res = client.post("/api/v1/media/upload", data=data, files=files, headers=headers)
    assert upload_res.status_code == 201
    media = upload_res.json()
    assert media["file_name"] == "banner.png"
    assert media["mime_type"] == "image/png"
    assert media["file_type"] == "image"
    media_id = media["id"]
    storage_path = media["storage_path"]

    # Verify file physically exists on disk
    assert os.path.exists(storage_path)

    # 2. Reject unsupported MIME type (e.g. executable script)
    bad_files = {"file": ("malicious.exe", io.BytesIO(b"MZ123"), "application/x-msdownload")}
    bad_res = client.post("/api/v1/media/upload", data=data, files=bad_files, headers=headers)
    assert bad_res.status_code == 400
    assert "not supported" in bad_res.json()["message"]

    # 3. Clean up and delete media
    del_res = client.delete(f"/api/v1/media/{media_id}", headers=headers)
    assert del_res.status_code == 204
    assert not os.path.exists(storage_path)

