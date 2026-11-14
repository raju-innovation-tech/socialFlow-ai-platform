# SocialFlow AI – Publishing Worker Setup & Operation

## 1. Running the Publishing Worker

The background worker claims due scheduled posts from PostgreSQL, checks Redis concurrency locks, dispatches content across platform adapters, and manages retries.

### Running as a Standalone Process (Windows 11 / Linux)
```powershell
cd "c:\Users\rkmau\Desktop\socialFlow ai\backend"
python -m app.publishing.workers.publishing_worker
```

### Running with Docker Compose
Add or run the worker service alongside API and Redis:
```yaml
  publishing-worker:
    build: ./backend
    command: python -m app.publishing.workers.publishing_worker
    environment:
      - DATABASE_URL=postgresql://socialflow:password@postgres:5432/socialflow_db
      - REDIS_URL=redis://redis:6379/0
    depends_on:
      - postgres
      - redis
    restart: always
```

---

## 2. Health Monitoring & Recovery

- **Stuck Job Recovery:** If a worker crashes while processing a job, `PublishingService` inspects jobs left in `in_progress` older than 10 minutes and reschedules them safely.
- **Graceful Shutdown:** The worker listens to `SIGINT` and `SIGTERM` signals, finishing active publishing jobs before shutting down cleanly.

