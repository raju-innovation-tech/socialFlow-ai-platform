# SocialFlow AI – Notifications Architecture (Phase 6)

## 1. Multi-Channel Notification Model

SocialFlow AI delivers real-time notifications across three independent delivery channels:
1. **In-App Notification Center**: Instant dashboard notifications, unread counters, and persistence in PostgreSQL (`notifications` table).
2. **Email Notifications**: Transactional alerts dispatched via SMTP/Email service to the user's verified address.
3. **Mobile & Web Push Notifications**: Device token registration for Firebase Cloud Messaging (FCM) / Apple Push Notification service (APNs).

---

## 2. Notification Event Triggers

The system automatically triggers event-driven notifications across core workflows:

| Event | Category | Title Sample | Trigger Conditions |
| :--- | :--- | :--- | :--- |
| `post_published` | `publishing` | "Post successfully published" | Publishing worker completes multi-target post |
| `post_failed` | `publishing` | "Publishing failed" | Target publishing encounters fatal error or exhausted retries |
| `token_expired` | `account` | "Instagram authorization expired" | Token refresh failure or 401 response from platform |
| `approval_requested` | `approval` | "New post approval requested" | Editor submits draft post for approver review |
| `system_alert` | `system` | "Scheduled maintenance window" | Platform developer / operator announcements |

---

## 3. Database Schema

- `notifications`: Scoped to `workspace_id` and `user_id`, holds `title`, `message`, `notification_type`, `is_read`, `metadata_json`.
- `notification_preferences`: Per-user matrix of `channel` (`in_app`, `email`, `push`) and `category` (`publishing`, `account`, `team`, `analytics`, `system`).
- `notification_delivery_logs`: Multi-channel audit trail with `delivery_status` (`sent`, `failed`, `pending`) and timestamp.
- `notification_devices`: FCM / APNs device tokens (`device_token`, `device_type`, `is_active`).

---

## 4. API Endpoints

- `GET /api/v1/notifications`: Scoped notification list with `unread_only` filter.
- `GET /api/v1/notifications/unread-count`: Fast unread count for topbar badges.
- `PATCH /api/v1/notifications/{id}/read`: Mark notification as read.
- `POST /api/v1/notifications/read-all`: Mark all workspace notifications as read.
- `DELETE /api/v1/notifications/{id}`: Delete notification.
- `GET /api/v1/notifications/preferences`: Get user notification preferences.
- `PATCH /api/v1/notifications/preferences`: Update channel/category preference.
- `POST /api/v1/notifications/devices/register`: Register mobile device push token.

