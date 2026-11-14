# SocialFlow AI – Phase 4: Seven Social Platform Integrations Audit

**Audit Date:** November 2026  
**Auditor:** Senior Backend Security Engineer & Integrations Architect  
**Project:** SocialFlow AI SaaS

---

## 1. Existing System Assessment

### A. Frontend Status (`flutter_admin/`)
- **UI & Navigation:** 47 fully built screens adhering to Bento Grid and Dark Premium Glassmorphism.
- **Social Account Module:**
  - `ConnectedAccountsScreen` (`/social-accounts`): Renders account cards, metrics, connection status pills, and disconnect dialogs.
  - `ConnectPlatformScreen` (`/social-accounts/connect`): Displays cards for all 7 platforms (LinkedIn, Facebook Pages, Instagram Professional, YouTube, X, WhatsApp Business, Telegram).
  - `AccountDetailsScreen` (`/social-accounts/details/:id`): Platform account metrics, follower count, sync controls, and token expiry status.
  - `PermissionsStatusScreen` (`/social-accounts/permissions`): Granular permission badges, reauthorization triggers.
- **Current Blocker in UI:** Screens previously read from `MockData.connectedAccounts`. They need to be wired to Riverpod `socialAccountsProvider` backed by `ApiClient` (Dio).

### B. Backend Status (`backend/`)
- **FastAPI Core & Security:**
  - Full Phase 3 authentication with rotating refresh token family tracking.
  - Granular RBAC (`owner`, `admin`, `editor`, `approver`, `analyst`, `viewer`) and Super Admin platform separation.
  - Strict tenant isolation enforced on every route via `get_active_workspace_member`.
  - Sensitive credential encryption at rest using Fernet AES-128-CBC (`credential_vault`).
- **Database Models (`backend/app/models/social_account.py`):**
  - `SocialPlatform`: Platform catalog with unique identifier.
  - `PlatformCapability`: Platform-level capability flags.
  - `SocialAccount`: Workspace-bound connected social account records.
  - `SocialAccountCredential`: Encrypted access and refresh tokens.
  - `SocialAccountPermission`: Granular scopes granted per account.
  - `OAuthState`: CSRF state tokens with TTL and workspace binding.
- **Database Missing Elements for Phase 4:**
  - `OAuthState` needs `code_verifier` column for PKCE-based OAuth (required by X/Twitter and modern LinkedIn).
  - `WebhookSubscription`: Webhook configurations per workspace/platform.
  - `IntegrationEvent`: Ingestion audit log for incoming webhook events (WhatsApp, Meta, Telegram).
  - `IntegrationSyncLog`: Metadata sync history per connected account.
  - Alembic migration needed: `phase4_integrations_and_webhooks`.

---

## 2. Platform Reality & API Specification Matrix

| Platform | Official API Used | Auth Method | Account Requirements | Major Restrictions & Realities |
| :--- | :--- | :--- | :--- | :--- |
| **1. LinkedIn** | LinkedIn Consumer & Community API | OAuth 2.0 (`openid`, `profile`, `email`, `w_member_social`) | Personal profile or verified Organization Page | Organization posting (`w_organization_social`) requires LinkedIn Community Management API approval. |
| **2. Facebook Pages** | Meta Graph API v20.0 | Facebook Login / OAuth 2.0 (`pages_show_list`, `pages_read_engagement`, `pages_manage_posts`) | Facebook Page admin rights | Personal profiles cannot be automated for posting. User selects specific Pages to connect. Page Access Token is exchanged for long-lived token. |
| **3. Instagram** | Instagram Graph API (via Meta) | Facebook Login / OAuth 2.0 (`instagram_basic`, `instagram_content_publish`) | Instagram Professional (Business or Creator) connected to a Facebook Page | Personal Instagram accounts are strictly unsupported by Meta Graph API. |
| **4. YouTube** | YouTube Data API v3 | Google OAuth 2.0 (`youtube.readonly`, `youtube.upload`) | Google Account with one or more YouTube Channels | Google OAuth grants channel management. Multi-channel accounts require user channel selection. Daily API quota is 10,000 units. |
| **5. X (Twitter)** | Official X API v2 | OAuth 2.0 with PKCE (`tweet.read`, `tweet.write`, `users.read`, `offline.access`) | Standard X Account | Free access tier is heavily restricted (write-only, 1,500 tweets/month). Basic tier ($100/mo) required for read metrics. |
| **6. WhatsApp** | Meta WhatsApp Business Platform (Cloud API) | System User Access Token / Embedded Signup (WABA ID + Phone Number ID) | Verified Meta Business Account with registered WABA | **Channels, Groups & Communities are NOT supported** by Cloud API for third-party automated SaaS publishing. Marked `manual_only` / `unavailable`. |
| **7. Telegram** | Official Telegram Bot API | Bot Token (`bot<token>`) | Registered Telegram Bot via `@BotFather` | Bot must be added as an Administrator to target channel or supergroup with `can_post_messages` permission. Cannot publish to private individual user chats without prior user interaction. |

---

## 3. Implementation Plan & Batch Order

1. **Batch 1:** Project audit, environment configuration (`.env.example`), and audit documentation.
2. **Batch 2:** Modular Integration Provider Architecture (`backend/app/integrations/base/`):
   - `base_provider.py`
   - `capability_models.py`
   - `integration_exceptions.py`
   - `token_manager.py`
   - `registry.py`
   - `integration_service.py`
3. **Batch 3:** Database Extensions & Alembic Migration:
   - Add `code_verifier` to `OAuthState`.
   - Add `WebhookSubscription`, `IntegrationEvent`, `IntegrationSyncLog`.
   - Create and run migration `phase4_integrations_and_webhooks`.
4. **Batch 4 - 10:** Seven Platform Provider Implementations:
   - `linkedin_provider.py`
   - `facebook_provider.py`
   - `instagram_provider.py`
   - `youtube_provider.py`
   - `x_provider.py`
   - `whatsapp_provider.py` (with explicit manual_only/unavailable constraints)
   - `telegram_provider.py` (with bot token validation, `getMe`, channel administrator checks)
5. **Batch 11:** Centralized Capability Engine & Capability Matrix.
6. **Batch 12:** FastAPI Integration & Webhook Endpoints:
   - Integration discovery, OAuth authorization URLs & callbacks, Telegram bot connection, WhatsApp webhook verification & receiver.
7. **Batch 13:** Flutter Frontend Integration:
   - Wire `socialAccountsProvider`, connect/disconnect flows, capability tags, platform logos, error dialogs.
8. **Batch 14:** Test Suite, Documentation & Verification Report.

