from datetime import datetime, timezone
from fastapi import FastAPI, Request, status
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from sqlalchemy.exc import SQLAlchemyError

from app.api.router import api_v1_router
from app.api.v1.health import get_system_health
from app.core.config import settings
from app.core.exceptions import AppException
from app.core.logging import logger, setup_logging
from app.middleware.request_id import RequestContextMiddleware

# Initialize logging configuration
setup_logging()

app = FastAPI(
    title=settings.APP_NAME,
    version="0.2.0",
    description="SocialFlow AI - Multi-Platform Social Media Management SaaS Backend API",
    docs_url="/docs",
    redoc_url="/redoc",
    openapi_url="/openapi.json",
)

# Request context & tracing middleware
app.add_middleware(RequestContextMiddleware)

# Cross-Origin Resource Sharing (CORS) for Flutter Web, Desktop & Mobile clients
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS if isinstance(settings.CORS_ORIGINS, list) else ["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
    expose_headers=["X-Request-ID", "X-Process-Time"],
)


# Exception Handlers
@app.exception_handler(AppException)
async def app_exception_handler(request: Request, exc: AppException):
    request_id = getattr(request.state, "request_id", None)
    return JSONResponse(
        status_code=exc.status_code,
        content={
            "error_code": exc.error_code,
            "message": exc.detail,
            "extra": exc.extra,
            "request_id": request_id,
            "timestamp": exc.timestamp,
        },
    )


@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    request_id = getattr(request.state, "request_id", None)
    return JSONResponse(
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        content={
            "error_code": "VALIDATION_ERROR",
            "message": "Invalid request parameters or payload",
            "errors": exc.errors(),
            "request_id": request_id,
            "timestamp": datetime.now(timezone.utc).isoformat(),
        },
    )


@app.exception_handler(SQLAlchemyError)
async def db_exception_handler(request: Request, exc: SQLAlchemyError):
    request_id = getattr(request.state, "request_id", None)
    logger.error("Database operation failed [%s]: %s", request_id, exc)
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={
            "error_code": "DATABASE_ERROR",
            "message": "A database error occurred while processing the request.",
            "request_id": request_id,
            "timestamp": datetime.now(timezone.utc).isoformat(),
        },
    )


@app.exception_handler(Exception)
async def unhandled_exception_handler(request: Request, exc: Exception):
    request_id = getattr(request.state, "request_id", None)
    logger.exception("Unhandled server exception [%s]: %s", request_id, exc)
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={
            "error_code": "INTERNAL_SERVER_ERROR",
            "message": "An unexpected internal error occurred.",
            "request_id": request_id,
            "timestamp": datetime.now(timezone.utc).isoformat(),
        },
    )


# Root health & meta routes
@app.get("/health", tags=["Health"])
def root_health():
    return get_system_health()


@app.get("/", tags=["Root"])
def root_index():
    return {
        "app": settings.APP_NAME,
        "version": "0.2.0",
        "phase": "Phase 2 - Backend & Database Foundation",
        "docs": "/docs",
        "health": "/health",
        "api_v1": settings.API_V1_PREFIX,
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }


# Mount API V1
app.include_router(api_v1_router, prefix=settings.API_V1_PREFIX)
