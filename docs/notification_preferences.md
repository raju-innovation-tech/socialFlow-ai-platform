# SocialFlow AI – Notification Preferences Specification (Phase 6)

## 1. Overview

Users maintain fine-grained control over which notifications they receive and through which channels. Every notification dispatch strictly evaluates user preferences prior to sending.

---

## 2. Channels & Categories Matrix

### Supported Channels
1. `in_app`: Web / Desktop / Mobile app notification center and topbar bell badge.
2. `email`: Direct email delivery to user's registered address.
3. `push`: Mobile FCM/APNs push notification to active registered devices.

### Supported Categories
1. `publishing`: Post published successfully, post publishing failed, retry exhausted.
2. `account`: Token expiry, reauthorization required, platform account disconnected.
3. `team`: New workspace member joined, role changed, invitation accepted.
4. `approval`: Post submitted for approval, post approved, post rejected.
5. `analytics`: Weekly performance summary, milestone reached.
6. `system`: Security notices, system updates, billing reminders.

---

## 3. Preference Evaluation Flow

```
[Event Trigger] 
       │
       ▼
[NotificationService.create_notification]
       │
       ├─► Check: In-App Enabled? ──► [Insert notifications record & delivery_log]
       │
       ├─► Check: Email Enabled? ──► [Dispatch Email & Insert delivery_log]
       │
       └─► Check: Push Enabled? ──► [Lookup notification_devices & Dispatch FCM]
```

Default State: All channels and categories default to `is_enabled = True` upon user onboarding.

