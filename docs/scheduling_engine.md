# SocialFlow AI – Scheduling Engine Specification

## 1. Scheduling Workflow

1. **User Action:** The user selects a target publication date and time, their desired timezone, target social accounts, and optional platform variants.
2. **Timezone Normalization:**
   - Input timestamp is translated from the workspace/user timezone (e.g. `America/New_York`, `Asia/Kolkata`, `Europe/London`) to **UTC**.
   - Input is rejected if `scheduled_at_utc <= now_utc`.
3. **Database Persistence:**
   - `posts.scheduled_at` is set to the normalized UTC timestamp.
   - `posts.status` transitions from `draft` to `scheduled`.
   - A `publishing_jobs` entry is created with `status="pending"`, `scheduled_time=scheduled_at_utc`, and an idempotency key.
4. **Execution & Recovery:**
   - The backend `PublishingWorker` queries `publishing_jobs` where `status == "pending"` and `scheduled_time <= now_utc`.
   - It claims due jobs using PostgreSQL's `SELECT ... FOR UPDATE SKIP LOCKED`.
   - If a server restarts or workers experience temporary downtime, due jobs are safely reclaimed during the next poll cycle without dropping or duplicating posts.
5. **Rescheduling & Cancellation:**
   - A scheduled post can be moved to a new time via `POST /api/v1/posts/{id}/schedule`.
   - Cancellation (`POST /api/v1/posts/{id}/cancel`) marks the pending job as `cancelled` and reverts the post to `draft`.

