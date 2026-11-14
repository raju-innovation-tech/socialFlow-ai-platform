# SocialFlow AI – Analytics Architecture (Phase 6)

## 1. Overview & Architectural Principles

The SocialFlow AI Analytics Engine collects, normalizes, stores, aggregates, and presents multi-platform social media performance metrics.

### Core Architectural Directives
1. **Truthful Platform Metrics**: Strict distinction between supported official platform metrics and restricted or unavailable platform data. No metric is ever invented or hallucinated.
2. **Zero-AI Guarantee**: Absolutely NO AI content generation, AI caption generation, AI recommendations, or fabricated insights. Metrics are pure mathematical calculations based on official platform API telemetry and database publishing jobs.
3. **Workspace Multi-Tenancy**: All analytics queries, snapshots, and aggregation pipelines are strictly partitioned by `workspace_id`.
4. **Resilient Provider Architecture**: Modular providers implement a unified interface (`BaseAnalyticsProvider`) with per-platform implementations for LinkedIn, Facebook, Instagram, YouTube, X (Twitter), WhatsApp Business, and Telegram.

---

## 2. Platform Telemetry & Availability Matrix

| Platform | Audience Metric | Post Impressions | Reach | Engagements (Likes/Comments/Shares) | Remarks |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **LinkedIn** | Org Followers | Lifetime Impressions | Organic Reach | Social Actions (Likes, Comments, Reposts) | Community Management API / Organization Insights |
| **Facebook Pages** | Page Likes / Followers | Page Post Impressions | Post Reach | Post Reactions, Comments, Shares | Meta Graph API `insights` endpoint |
| **Instagram Professional** | Profile Followers | Media Impressions | Media Reach | Likes, Comments, Saves, Shares | Instagram Graph API Insights (`business_discovery`/insights) |
| **YouTube** | Channel Subscribers | Video Views | Channel Reach | Likes, Comments, Views | YouTube Data API v3 (`statistics`) |
| **X (Twitter)** | Followers Count | Tweet Impressions | Not Exposed by API | Retweets, Likes, Replies | Twitter API v2 (`tweet.fields=public_metrics`) |
| **WhatsApp Business** | *Unavailable* | *Unavailable* | *Unavailable* | Sent/Delivered/Read counts | Direct messaging platform; no audience reach or public feed |
| **Telegram** | Channel Members | *Unavailable* (Bot API) | *Unavailable* (Bot API) | *Unavailable* (Bot API) | `getChatMemberCount` supported; individual post impressions not exposed to Bot API |

---

## 3. Database Schema

- `analytics_snapshots`: Daily historical snapshots per connected account (`account_id`, `snapshot_date`, `followers_count`, `impressions_count`, `reach_count`, `engagement_rate`).
- `post_metrics`: Post-level performance across individual targets (`post_id`, `social_account_id`, `impressions`, `reach`, `likes`, `comments`, `shares`, `clicks`).
- `platform_metrics`: Workspace platform aggregate records.

---

## 4. Background Sync Daemon

`AnalyticsSyncWorker` runs periodically (`backend/app/analytics/workers/analytics_sync_worker.py`) to cycle across all workspaces, calling `AnalyticsSyncService.sync_workspace(workspace_id)` to update account metrics and capture daily snapshots.

