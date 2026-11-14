# SocialFlow AI – Plan Entitlements & Feature Limits (Phase 7)

## 1. Centralized Entitlement Keys

Every workspace subscription maps to real-time limits enforced by `EntitlementService`:

- `social_accounts.max_total`: Maximum connected social media channels across all 7 platforms.
- `workspace_members.max_total`: Maximum team members allowed in the workspace.
- `publishing.targets_per_month`: Maximum post targets published during the billing cycle.
- `media.storage_bytes`: Maximum total file storage for media library assets.
- `analytics.history_days`: Days of historical analytics snapshots accessible.
- `reports.export_enabled`: Boolean flag allowing CSV/PDF performance exports.
- `team.approvals_enabled`: Multi-step post approval workflows.

---

## 2. Server-Side Enforcement Points

Entitlements are strictly checked in backend services:
1. **Account Connection (`assert_can_connect_account`)**: Checked before generating OAuth state or saving credentials.
2. **Publishing Execution (`assert_can_publish_targets`)**: Checked before scheduling or immediate target dispatch.
3. **Workspace Invitations (`assert_can_invite_member`)**: Checked before sending invitations.
4. **Report Export (`assert_can_export_reports`)**: Checked in `/api/v1/analytics/reports/export`.

