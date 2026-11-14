# SocialFlow AI – Backend Architecture Specification (Phase 2)

## 1. Architectural Overview

SocialFlow AI is designed as a multi-tenant, enterprise-grade social media management SaaS platform. The Phase 2 backend provides a clean layered architecture adhering to Domain-Driven Design (DDD) principles:

```
FastAPI Routing Layer (app/api/v1/)
       │
       ▼
Application Service Layer (app/services/)
       │
       ▼
Repository & Data Access Layer (app/repositories/)
       │
       ▼
SQLAlchemy 2.0 ORM & PostgreSQL 16 (app/models/)
       │
Redis Cache & Temporary State Layer (app/core/redis.py)
```

## 2. Layer Responsibilities

- **API Layer (`app/api/v1/`)**: Pure HTTP transport layer. Validates inbound requests with Pydantic v2 schemas, handles dependency injection (`get_db`), and returns typed JSON responses.
- **Service Layer (`app/services/`)**: Enforces business logic, credentials encryption via Fernet, cross-entity rules, file upload storage validation, and orchestrates repository calls.
- **Repository Layer (`app/repositories/`)**: Abstracted database query interface inheriting from `BaseRepository[T]` with type-safe filtering, pagination, and transactional commits/rollbacks.
- **Core Infrastructure (`app/core/`)**:
  - `config.py`: Environment-driven settings with validation.
  - `database.py`: SQLAlchemy 2.0 session factory with connection pooling.
  - `redis.py`: Resilient Redis client with ping health-checks and caching helpers.
  - `security.py`: Fernet AES-128-CBC + HMAC-SHA256 symmetric token encryption.
  - `logging.py`: Structured UTC ISO timestamped logging.
  - `exceptions.py`: Centralized API error hierarchy.

## 3. Security & Multi-Tenancy Architecture

- **Credential Protection**: Social account tokens (LinkedIn, Meta, X, YouTube, Telegram bot tokens) are encrypted before insertion into `social_account_credentials`.
- **Tenant Isolation**: Every core entity (`posts`, `social_accounts`, `campaigns`, `media_assets`, `notifications`) contains an indexed `workspace_id` foreign key.
- **Request Tracing**: Every inbound request receives an `X-Request-ID` UUID header and execution time header (`X-Process-Time`).

