# SocialFlow AI – Phase 5: Real Publishing & Scheduling Audit

## 1. Executive Summary

This audit assesses the readiness of SocialFlow AI for **Phase 5: Real Publishing + Scheduling Engine**.
Building upon Phase 1 (Flutter UI), Phase 2 (FastAPI, PostgreSQL, Redis), Phase 3 (Auth, Multi-tenancy, RBAC), and Phase 4 (7 Social Platform Integrations), Phase 5 implements the real background execution engine that publishes user-crafted content to connected social accounts.

**Key Rule:** No AI content generation. Users provide their own images, videos, captions, text, hashtags, and links.

---

## 2. Component Inspection & Baseline Status

### A. Frontend (Flutter UI)
- **Publishing Screens:**
  * `create_post_screen.dart`: Multi-account selector, caption input, media picker preview, platform variation tabs, and schedule date/time pickers.
  * `platform_editor_screen.dart`: Per-platform text customization and validation previews.
  * `multi_preview_screen.dart`: Realistic live mockup rendering for LinkedIn, Facebook, Instagram, YouTube, X, WhatsApp, and Telegram.
  * `publishing_queue_screen.dart`: Queued, processing, scheduled, and failed job inspector.
  * `publishing_history_screen.dart`: Audited publishing logs with external post IDs and direct URLs.
  * `drafts_screen.dart`: In-progress draft manager.
- **Calendar Screens:**
  * `calendar_screen.dart`: Day, week, and month visual timeline of scheduled and published content with platform badges.
- **Approvals:**
  * `approval_inbox_screen.dart` & `approval_details_screen.dart`: RBAC-governed post review queue for Approvers, Admins, and Owners.
- **Status:** UI structure exists from Phase 1. Currently uses mock data or static stubs. Needs Riverpod providers and services to connect to Phase 5 backend APIs.

### B. Backend Architecture & Database Models
- **Post & Variant Models (`backend/app/models/post.py`):**
  * `Post`: Primary post container with `workspace_id`, `category_id`, `title`, `content`, `content_type`, `status`, `scheduled_at`, `published_at`.
  * `PostVariant`: Platform-specific customized content (`platform`, `customized_content`).
  * `PostTarget`: Per-account publishing target (`social_account_id`, `status`, `external_post_id`, `error_message`, `published_at`).
  * `PostMedia`: Ordered association between posts and `media_assets`.
- **Publishing Models (`backend/app/models/publishing.py`):**
  * `PublishingJob`: Background job tracker with `idempotency_key`, `scheduled_time`, `status`, `retry_count`, `max_retries`, `last_error`.
  * `PublishingAttempt`: Per-execution audit log with `duration_ms`, `response_payload`, `error_details`.
  * `PublishingOutbox`: Transactional outbox event table (`aggregate_id`, `event_type`, `payload`, `status`).
- **Media Models (`backend/app/models/media.py`):**
  * `MediaAsset`: File metadata, dimensions, duration, MIME types, and storage paths.
- **Status:** Database models and Alembic migrations for all core publishing entities are already in place.

### C. Platform Integrations & Credentials (Phase 4 Foundation)
- All 7 platform concrete providers are implemented in `backend/app/integrations/`:
  1. `LinkedInProvider`: REST & Community API v2 token management and OpenID Connect.
  2. `FacebookProvider`: Meta Graph API v20.0 Page discovery and permanent page token acquisition.
  3. `InstagramProvider`: Instagram Graph API v20.0 Business/Creator account link verification.
  4. `YouTubeProvider`: Google OAuth 2.0 and channel discovery via YouTube Data API v3.
  5. `XProvider`: X API v2 OAuth 2.0 with PKCE (`S256`).
  6. `WhatsAppProvider`: Meta Cloud API onboarding and webhook event handling.
  7. `TelegramProvider`: Telegram Bot API token validation and administrator checking.
- **Token Security:** `TokenManager` provides AES-128-CBC encryption and decryption of tokens stored in PostgreSQL.

### D. Redis & Background Task Infrastructure
- Redis is configured in `backend/app/core/redis.py` with connection pooling and health checks.
- Requirement for Phase 5: A robust worker and scheduling daemon that claims jobs atomically from PostgreSQL, uses Redis for queueing/locking, and recovers gracefully on restart.

---

## 3. Platform Publishing Capabilities & Restrictions

| Platform | Supported Publishing Types | API Endpoints | Specific Limitations |
| :--- | :--- | :--- | :--- |
| **LinkedIn** | Text, Single Image, Carousel (PDF/Images), Video | `/v2/ugcPosts` or `/rest/posts` | Organization posts require `w_organization_social`. Max 3,000 characters. |
| **Facebook Pages** | Text, Single/Multiple Photos, Reels, Videos | `/{page_id}/feed`, `/{page_id}/photos`, `/{page_id}/videos` | Personal profiles unsupported. Page access token required. Max 63,206 chars. |
| **Instagram Pro** | Single Image, Carousel, Reels, Video | `/{ig_id}/media` -> wait -> `/{ig_id}/media_publish` | 2-step container publishing. Aspect ratio 4:5 to 1.91:1. Personal accounts blocked. |
| **YouTube** | Video Uploads, Shorts | `POST /upload/youtube/v3/videos?uploadType=resumable` | Video required (no pure text/image). 10,000 quota units/day default (1,600 units/upload). |
| **X (Twitter)** | Text, Single/Multiple Images, Video | `POST /2/tweets` (Media via `/1.1/media/upload`) | 280 character limit (Standard). Free tier allows write-only up to 1,500 tweets/month. |
| **WhatsApp** | Session text, media messages, Template broadcasts | `POST /v20.0/{phone_number_id}/messages` | **Channels, Groups, Communities UNAVAILABLE via API**. Requires approved template if outside 24h window. |
| **Telegram** | Text, Photos, Videos, Documents to Channels & Groups | `/sendMessage`, `/sendPhoto`, `/sendVideo` | Bot must be administrator in channel with `can_post_messages: true`. 4,096 char limit. |

---

## 4. Phase 5 Implementation Plan

1. **Batch 1:** Audit & documentation (this file and `docs/publishing_capability_matrix.md`).
2. **Batch 2 & 3:** Post management, platform variations, and repository enhancements.
3. **Batch 4:** Media validation and processing service (file size, dimensions, formats).
4. **Batch 5:** Publishing state machine and lifecycle manager.
5. **Batch 6 & 7:** Background worker and scheduling engine using Redis and transactional PostgreSQL outbox/job claiming.
6. **Batches 8-14:** Seven concrete platform publishing adapters:
   - `LinkedInPublisher`
   - `FacebookPublisher`
   - `InstagramPublisher`
   - `YouTubePublisher`
   - `XPublisher`
   - `WhatsAppPublisher`
   - `TelegramPublisher`
7. **Batch 15 & 16:** Multi-platform publishing orchestrator, idempotency locks, and exponential backoff retry manager.
8. **Batch 17:** RBAC and post approval workflow enforcement.
9. **Batch 18 & 19:** Flutter frontend integration (`CreatePostScreen`, `CalendarScreen`, `PublishingQueueScreen`, Riverpod `publishingProvider`).
10. **Batch 20:** Automated test suite (pytest + HTTPX, flutter analyze, flutter test) and final completion report.

