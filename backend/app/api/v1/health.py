from fastapi import APIRouter
from app.core.database import check_db_health
from app.core.redis import redis_service
from app.schemas.health import ServiceHealthResponse, SystemHealthResponse

router = APIRouter(tags=["Health"])


@router.get("/health", response_model=SystemHealthResponse)
def get_system_health():
    db_status = check_db_health()
    redis_status = redis_service.check_health()

    overall = "healthy"
    if db_status.get("status") != "healthy" or redis_status.get("status") != "healthy":
        overall = "degraded"

    return SystemHealthResponse(
        app="SocialFlow AI Backend",
        version="0.2.0",
        environment="development",
        status=overall,
        database=db_status,
        redis=redis_status,
    )


@router.get("/health/database", response_model=ServiceHealthResponse)
def get_database_health():
    res = check_db_health()
    return ServiceHealthResponse(status=res.get("status", "unknown"), details=res)


@router.get("/health/redis", response_model=ServiceHealthResponse)
def get_redis_health():
    res = redis_service.check_health()
    return ServiceHealthResponse(status=res.get("status", "unknown"), details=res)

