# SocialFlow AI – Enterprise Social Media Management SaaS

SocialFlow AI is an enterprise-grade multi-platform social media operating system supporting LinkedIn, Facebook, Instagram, YouTube, X, WhatsApp, and Telegram.

---

## Clean Project Structure

```
c:\Users\rkmau\Desktop\socialFlow ai\
├── flutter_admin/           # Phase 1: Complete Flutter UI (47 screens, Material 3, Bento Grid)
│   ├── lib/                 # App router, theme, providers, network client, features
│   ├── test/                # Automated widget and navigation tests
│   ├── android/, ios/, etc. # Native platform shells (Windows, Web, Mobile)
│   ├── pubspec.yaml         # Dependencies (Riverpod, GoRouter, Dio, FL Chart, Lucide Icons)
│   └── analysis_options.yaml
├── backend/                 # Phase 2 & 3: FastAPI + PostgreSQL + Redis + Auth & RBAC
│   ├── app/
│   │   ├── api/v1/          # 70 REST API endpoints (Auth, Workspaces, Posts, Admin, etc.)
│   │   ├── cli/             # Management tools (Super Admin bootstrap CLI)
│   │   ├── core/            # Config, DB, Redis, Logging, Fernet Encryption, JWT, RBAC
│   │   ├── models/          # 48 SQLAlchemy 2.0 tables (Auth tokens, sessions, memberships)
│   │   ├── repositories/    # Clean Data Access Layer (BaseRepository[T])
│   │   ├── services/        # Business logic (AuthService, WorkspaceService, etc.)
│   │   └── schemas/         # Pydantic v2 validation contracts
│   ├── alembic/             # Database migration versions (including Phase 3 batch migration)
│   └── tests/               # 19 automated test suites (100% passing)
├── docs/                    # Technical architecture & integration documentation
│   ├── authentication.md    # Registration, login, OTP verification, password reset
│   ├── token_management.md  # Short-lived JWTs & rotating refresh token family theft detection
│   ├── multi_tenancy.md     # Pooled multi-tenancy & workspace switching
│   ├── rbac_permissions.md  # 6 workspace roles + platform Super Admin separation
│   ├── workspace_invitations.md # Team invitations, member management & ownership transfer
│   └── tenant_security.md   # Zero-trust tenant isolation & encryption
├── docker-compose.yml       # PostgreSQL (5434), Redis (6380), FastAPI (8001)
└── README.md
```

---

## Execution Commands

### 1. Run Flutter Admin UI (Desktop / Web)
```powershell
cd "c:\Users\rkmau\Desktop\socialFlow ai\flutter_admin"
flutter run -d windows
# or run in Chrome:
flutter run -d chrome
```

### 2. Run Backend (FastAPI Server)
```powershell
cd "c:\Users\rkmau\Desktop\socialFlow ai\backend"
python -m uvicorn app.main:app --host 0.0.0.0 --port 8001 --reload
```
- Interactive Swagger UI: `http://localhost:8001/docs`
- Health check: `http://localhost:8001/health`

### 3. Bootstrap Platform Super Admin
```powershell
cd "c:\Users\rkmau\Desktop\socialFlow ai\backend"
python -m app.cli.manage create-super-admin --email admin@socialflow.ai --password "SuperSecretPassword123!" --name "Platform Super Admin"
```

### 4. Run Automated Tests
```powershell
# Backend Test Suite (19 tests: Auth, RTR, Tenant Isolation, RBAC, Posts, Media)
pytest backend/tests -v

# Flutter Frontend Analysis & Tests
cd "c:\Users\rkmau\Desktop\socialFlow ai\flutter_admin"
flutter analyze
flutter test
```

# Run Flutter tests
cd "c:\Users\rkmau\Desktop\socialFlow ai\flutter_admin"
flutter test

# Run Backend tests
cd "c:\Users\rkmau\Desktop\socialFlow ai"
pytest backend/tests
```
