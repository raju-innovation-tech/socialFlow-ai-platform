# SocialFlow AI – Phase 6: Analytics & Notifications Audit

## 1. Executive Summary

This audit assesses the readiness of SocialFlow AI for **Phase 6: Real Analytics + Notification System**.
Building upon:
- Phase 1 (Flutter UI Design System)
- Phase 2 (FastAPI, PostgreSQL, Redis Foundation)
- Phase 3 (Authentication, Multi-Tenancy, RBAC)
- Phase 4 (Seven Social Platform Integrations & OAuth Credentials)
- Phase 5 (Real Publishing & Scheduling Engine)

**Core Mandates:**
1. **Zero AI:** No AI content generation, AI caption generation, or synthetic data.
2. **Actual Platform Data:** Collect and compute metrics from official APIs where available; explicitly demarcate unavailable or restricted metrics.
3. **Event-Driven Notifications:** Real in-app alerts, email notifications, and push notification routing for actual system events.

---

## 2. Component Inspection & Baseline

### A. Database Models (`backend/app/models/analytics.py` & `notification.py`)
- `AnalyticsSnapshot`: Daily time-series table per connected social account (`followers_count`, `impressions_count`, `reach_count`, `engagement_rate`, `raw_metrics_json`).
- `PlatformMetric`: Cross-platform aggregate metrics by date and dimension tags.
- `PostMetric`: Post-level performance tracking (`impressions`, `reach`, `likes`, `comments`, `shares`, `clicks`).
- `Notification`: In-app notification queue with workspace and user isolation (`notification_type`, `is_read`, `metadata_json`).
- `NotificationPreference`: User-configurable delivery preferences (`channel`, `category`, `is_enabled`).
- `NotificationDeliveryLog`: Audit log of notification delivery outcomes.
- **Requirement for Phase 6:** Add `NotificationDevice` to store mobile/web FCM device push tokens.

### B. Platform API Analytics Capabilities

| Platform | Official Analytics API | Supported Metrics | Limitations & Restrictions |
| :--- | :--- | :--- | :--- |
| **LinkedIn** | Community Management & Consumer API | Followers, Follower Growth, Impressions, Reactions, Comments, Shares | Organization metrics require `r_organization_social`. Personal profile post analytics require specific member scopes. |
| **Facebook Pages** | Meta Graph API v20.0 Page Insights (`/{page_id}/insights`) | Page Followers, Reach, Impressions, Post Views, Reactions, Comments, Shares | Personal profiles unsupported. Metric granularity (day, week, days_28). |
| **Instagram Pro** | Instagram Graph API Insights (`/{ig_id}/insights`) | Reach, Accounts Engaged, Profile Activity, Impressions, Likes, Comments, Saves, Reels views | Business/Creator accounts linked to Facebook Pages only. Personal accounts blocked. |
| **YouTube** | YouTube Data API v3 & YouTube Analytics API | Channel Views, Subscribers, Video Views, Likes, Comments, Estimated Minutes Watched | Quota limits apply. Revenue metrics require separate YouTube Partner approval. |
| **X (Twitter)** | Official X API v2 Tweet & User Metrics | Followers, Impressions, Likes, Retweets, Replies, Quotes | Free tier provides basic public counts; advanced historical analytics require Basic ($100/mo) tier. |
| **WhatsApp** | Meta Cloud API Analytics (`/{waba_id}` & webhooks) | Messages Sent, Delivered, Read, Failed, Template Status | **Channels & Groups are UNAVAILABLE via API**. No social post reach/likes. |
| **Telegram** | Telegram Bot API | Bot messages sent, Channel member count (`getChatMemberCount`) | **No official API for channel post impressions/reach**. Mark impressions as unavailable. |

### C. Frontend Screens
- `flutter_admin/lib/features/analytics/screens/analytics_overview_screen.dart`
- `flutter_admin/lib/features/analytics/screens/platform_analytics_screen.dart`
- `flutter_admin/lib/features/analytics/screens/reports_export_screen.dart`
- Need connection to live Riverpod `analyticsProvider` and `notificationsProvider`.

