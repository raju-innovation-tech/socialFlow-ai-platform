from typing import Any, Optional
import redis
from app.core.config import settings
from app.core.logging import logger


class RedisClient:
    def __init__(self):
        self._client: Optional[redis.Redis] = None

    def get_client(self) -> redis.Redis:
        if self._client is None:
            self._client = redis.from_url(
                settings.REDIS_URL,
                decode_responses=True,
                socket_timeout=settings.REDIS_SOCKET_TIMEOUT,
                max_connections=settings.REDIS_MAX_CONNECTIONS,
            )
        return self._client

    def ping(self) -> bool:
        try:
            client = self.get_client()
            return bool(client.ping())
        except Exception as e:
            logger.warning("Redis ping failed: %s", e)
            return False

    def get(self, key: str) -> Optional[str]:
        try:
            return self.get_client().get(key)
        except Exception as e:
            logger.error("Redis GET failed for key '%s': %s", key, e)
            return None

    def set(self, key: str, value: Any, ex: Optional[int] = None) -> bool:
        try:
            return bool(self.get_client().set(key, str(value), ex=ex))
        except Exception as e:
            logger.error("Redis SET failed for key '%s': %s", key, e)
            return False

    def delete(self, key: str) -> bool:
        try:
            return bool(self.get_client().delete(key))
        except Exception as e:
            logger.error("Redis DELETE failed for key '%s': %s", key, e)
            return False

    def check_health(self) -> dict:
        try:
            alive = self.ping()
            if alive:
                return {"status": "healthy", "redis": "connected"}
            return {"status": "degraded", "redis": "unreachable"}
        except Exception as e:
            return {"status": "unhealthy", "error": str(e)}


redis_service = RedisClient()

