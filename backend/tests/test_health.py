from unittest.mock import patch


def test_root_index(client):
    response = client.get("/")
    assert response.status_code == 200
    data = response.json()
    assert data["app"] == "SocialFlow AI"
    assert data["version"] == "0.2.0"
    assert "/docs" in data["docs"]


def test_root_health(client):
    with patch("app.core.redis.redis_service.check_health", return_value={"status": "healthy", "redis": "connected"}):
        response = client.get("/health")
        assert response.status_code == 200
        data = response.json()
        assert "status" in data
        assert "database" in data
        assert "redis" in data


def test_api_v1_health_database(client):
    response = client.get("/api/v1/health/database")
    assert response.status_code == 200
    data = response.json()
    assert "status" in data


def test_api_v1_health_redis(client):
    with patch("app.core.redis.redis_service.check_health", return_value={"status": "healthy", "redis": "connected"}):
        response = client.get("/api/v1/health/redis")
        assert response.status_code == 200
        data = response.json()
        assert "status" in data

