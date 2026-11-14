# SocialFlow AI – Local Environment Setup Guide

## Requirements
- Python 3.11+
- Windows PowerShell
- PostgreSQL 15+ (or Docker)
- Redis 7+ (or Docker)

## Step-by-Step Setup

### 1. Copy Environment Variables
```powershell
cd "c:\Users\rkmau\Desktop\socialFlow ai\backend"
Copy-Item .env.example .env
```

### 2. Install Dependencies
```powershell
python -m pip install -r requirements.txt
```

### 3. Run Database Migrations
```powershell
alembic -c alembic.ini upgrade head
```

### 4. Start Backend Server
```powershell
uvicorn app.main:app --host 0.0.0.0 --port 8001 --reload
```

### 5. Run Automated Tests
```powershell
pytest tests
```

