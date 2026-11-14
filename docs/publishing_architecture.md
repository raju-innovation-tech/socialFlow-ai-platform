# SocialFlow AI – Publishing & Scheduling Architecture

## 1. System Overview

SocialFlow AI's Phase 5 Publishing Engine is a multi-tenant, omni-channel publishing pipeline designed to dispatch user-authored content across 7 major social networks using their official REST and Graph APIs.

```
+-----------------------------------------------------------------------------------+
|                              Flutter Frontend Client                              |
|   (Create Post, Multi-Platform Editor, Preview, Calendar, Active Queue, History)  |
+------------------------------------------+----------------------------------------+
                                           | HTTPS / JSON
                                           v
+-----------------------------------------------------------------------------------+
|                                FastAPI Backend API                                |
|   - POST /api/v1/posts (Draft creation, variants, targets)                        |
|   - POST /api/v1/posts/{id}/publish (Immediate execution)                         |
|   - POST /api/v1/posts/{id}/schedule (Future UTC scheduling)                      |
|   - GET  /api/v1/publishing/calendar & queue                                      |
+---------------------+---------------------------------------+---------------------+
                      |                                       |
                      v                                       v
+-----------------------------------+   +-------------------------------------------+
|      PostgreSQL (Source of Truth) |   |             Redis Infrastructure          |
|  - posts & post_variants          |   |  - Idempotency Locks                      |
|  - post_targets                   |   |  - Pub/Sub Queue Distribution             |
|  - publishing_jobs (Atomic claim) |   |  - Token Caching                          |
|  - publishing_attempts (Audit)    |   +-------------------------------------------+
+---------------------+-------------+
                      |
                      v
+-----------------------------------------------------------------------------------+
|                      PublishingWorker (Background Execution Loop)                 |
|  - Atomic job claiming with `SELECT ... FOR UPDATE SKIP LOCKED`                    |
|  - Multi-platform dispatch via `PublishingService`                                |
|  - Exponential backoff & jitter via `RetryService`                                |
+------------------------------------------+----------------------------------------+
                                           |
                                           v
+-----------------------------------------------------------------------------------+
|                          Platform Publishing Adapters                             |
|  LinkedIn       Facebook       Instagram       YouTube       X       WhatsApp     Telegram |
+-----------------------------------------------------------------------------------+
```

---

## 2. Key Components

### A. Publishing Adapters (`backend/app/publishing/adapters/`)
- **`BasePublishingAdapter`:** Defines standard `validate_content()` and `publish()` contracts.
- **7 Concrete Platform Publishers:**
  1. `LinkedInPublisher`: Generates UGC Share Posts (`/v2/ugcPosts`) with personal vs organization distinction.
  2. `FacebookPublisher`: Publishes to Facebook Pages (`/{page_id}/feed`, `photos`, `videos`) using Page Access Tokens.
  3. `InstagramPublisher`: Two-step asynchronous media container workflow (`/media` -> status wait -> `/media_publish`).
  4. `YouTubePublisher`: Resumable video upload session (`/upload/youtube/v3/videos?uploadType=resumable`).
  5. `XPublisher`: Character validation (280) and v2 Tweet creation (`/2/tweets`).
  6. `WhatsAppPublisher`: Meta Cloud API messaging (`/v20.0/{phone_number_id}/messages`). Explicitly marks Channels & Groups as unavailable.
  7. `TelegramPublisher`: BotFather HTTP Bot API (`/sendMessage`, `/sendPhoto`, `/sendVideo`).
- **`PublishingAdapterRegistry`:** Singleton registry providing instant lookup of active adapters.

### B. Validation Service (`backend/app/publishing/services/validation_service.py`)
Pre-flight content and media inspection before post creation or publishing, checking platform-specific constraints independently for each platform variant.

### C. Publishing Service (`backend/app/publishing/services/publishing_service.py`)
- Coordinates multi-account dispatch.
- Uses `TokenManager` to decrypt sensitive OAuth tokens stored in PostgreSQL.
- Implements Redis-backed concurrency locks (`lock:pub:{post_id}:{target_id}`) preventing double-clicking duplicate publication.
- Records all attempts in `publishing_attempts` with duration in milliseconds.

### D. Scheduling Engine (`backend/app/publishing/services/scheduling_service.py`)
- Enforces UTC normalization for all scheduled timestamps.
- Prevents scheduling in the past.
- Supports instant cancellation and rescheduling.
- Employs atomic job claiming via `with_for_update(skip_locked=True)` so multiple worker instances never execute the same job twice.

