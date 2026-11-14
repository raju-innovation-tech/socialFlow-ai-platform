# SocialFlow AI – Database Schema Reference

The database consists of **41 relational tables** mapped with SQLAlchemy 2.0 and Alembic migrations.

## Functional Modules & Tables

### 1. User & Workspace Foundation
- `users`: Core user accounts (id, email, full_name, hashed_password, is_active, is_verified, is_super_admin).
- `user_profiles`: User preferences (avatar_url, bio, timezone, language, phone_number).
- `workspaces`: Multi-tenant customer accounts (id, name, slug, description, logo_url, is_active).
- `workspace_members`: User-to-workspace roles (owner, admin, editor, approver, analyst, viewer).
- `workspace_invitations`: Team invitations with secure expiration tokens.

### 2. Social Account Management
- `social_platforms`: Platform catalogue (linkedin, facebook, instagram, youtube, x, whatsapp, telegram).
- `platform_capabilities`: Granular feature matrix (direct_publish, reels, carousels, analytics).
- `social_accounts`: Connected brand accounts per workspace.
- `social_account_credentials`: Fernet encrypted access and refresh tokens.
- `social_account_permissions`: Granular OAuth permission scopes.
- `oauth_states`: CSRF-protected temporary authorization states.

### 3. Content Publishing
- `content_categories`: Color-coded content pillars for post organization.
- `posts`: Core post entity with status (draft, scheduled, publishing, published, failed, pending_approval).
- `post_variants`: Per-platform adapted text and caption overrides.
- `post_targets`: Account-specific target queue and published external IDs.
- `post_media`: Display order mapping for attached media items.

### 4. Media Management
- `media_assets`: Uploaded images, videos, and documents with sha256 checksums, MIME types, and storage paths.
- `media_folders`: Organizational folder tree with parent-child hierarchy.
- `media_folder_items`: Mapping between media assets and folders.

### 5. Campaign Management
- `campaigns`: Marketing initiatives with budgets, currency, and date ranges.
- `campaign_posts`: Many-to-many relationship linking posts to campaigns.

### 6. Publishing Engine Foundation (Prepared for Phase 5)
- `publishing_jobs`: Scheduled job registry with max retries and idempotency keys.
- `publishing_attempts`: Detailed execution history with latency and error payloads.
- `publishing_outbox`: Transactional outbox event stream.

### 7. Analytics Foundation
- `analytics_snapshots`: Daily account-level metrics (followers, impressions, reach, engagement).
- `platform_metrics`: Aggregated per-network performance trends.
- `post_metrics`: Fine-grained post performance (likes, shares, comments, clicks).

### 8. Notifications Foundation
- `notifications`: User and workspace activity notifications.
- `notification_preferences`: Per-channel alert preferences (in_app, email, webhook).
- `notification_delivery_logs`: Delivery audit records.

### 9. Team & Approvals Foundation (Prepared for Phase 3)
- `workspace_roles`: Custom role definitions.
- `permissions`: Fine-grained permission catalogue.
- `role_permissions`: Role-to-permission mapping.
- `post_approvals`: Reviewer approval/rejection notes and status tracking.

### 10. Billing Foundation (Prepared for Phase 7)
- `subscription_plans`: Pricing tiers (Free, Pro, Enterprise) with quotas.
- `workspace_subscriptions`: Active workspace subscription periods and status.
- `billing_customers`: Stripe/payment gateway customer mapping.
- `invoices`: Monetary records and invoice URLs.
- `payment_events`: Webhook event audit trail.
- `usage_records`: AI credit and post quota tracking.

### 11. Platform Audit
- `audit_logs`: Immutable security log of all administrative and mutation events.

