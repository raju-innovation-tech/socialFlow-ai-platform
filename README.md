# SocialFlow AI – Enterprise Social Media Management SaaS

SocialFlow AI is an enterprise-grade multi-platform social media operating system supporting LinkedIn, Facebook, Instagram, YouTube, X, WhatsApp, and Telegram.

---

## Clean Project Structure

```
c:\Users\rkmau\Desktop\socialFlow ai\
├── flutter_admin/           # Phase 1: Complete Flutter UI (47 screens, Material 3, Bento Grid)
│   ├── lib/                 # App router, theme, providers, features
│   ├── test/                # Automated widget and navigation tests
│   ├── android/, ios/, etc. # Native platform shells (Windows, Web, Mobile)
│   ├── pubspec.yaml         # Dependencies (Riverpod, GoRouter, FL Chart, Lucide Icons)
│   └── analysis_options.yaml
├── backend/                 # Phase 2: FastAPI + PostgreSQL + Redis Backend
│   ├── app/
│   │   ├── api/v1/          # 41 REST API endpoints
│   │   ├── core/            # Config, DB, Redis, Logging, Fernet Token Encryption
│   │   ├── models/          # 41 SQLAlchemy 2.0 tables
│   │   ├── repositories/    # Clean Data Access Layer (BaseRepository[T])
│   │   ├── services/        # Business logic & local media storage
│   │   └── schemas/         # Pydantic v2 validation contracts
│   ├── alembic/             # Database migration versions
│   └── tests/               # 13 automated test suites
├── docs/                    # Technical architecture & integration documentation
├── docker-compose.yml       # PostgreSQL (5434), Redis (6380), FastAPI (8001)
├── uploads/                 # Local development media storage
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

### 3. Run Backend via Docker Compose
```powershell
cd "c:\Users\rkmau\Desktop\socialFlow ai"
docker-compose up -d --build
```

### 4. Run Automated Tests
```powershell
# Run Flutter tests
cd "c:\Users\rkmau\Desktop\socialFlow ai\flutter_admin"
flutter test

# Run Backend tests
cd "c:\Users\rkmau\Desktop\socialFlow ai"
pytest backend/tests
```
