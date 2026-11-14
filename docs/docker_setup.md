# SocialFlow AI – Docker & Compose Setup

## Architecture
The Docker Compose deployment spins up 3 isolated services:
1. `socialflow_backend`: FastAPI app running on port `8001`.
2. `socialflow_postgres`: PostgreSQL 16 on host port `5434` (mapped internally to 5432).
3. `socialflow_redis`: Redis 7 on host port `6380` (mapped internally to 6379).

## Running with Docker Compose

From the root project directory:
```powershell
docker-compose up -d --build
```

### Check Logs & Health:
```powershell
docker-compose ps
docker-compose logs -f backend
```

### Stop Containers:
```powershell
docker-compose down
```

