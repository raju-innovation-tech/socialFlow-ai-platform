# Multi-Tenancy & Workspace Switching

## 1. Multi-Tenant Architecture
SocialFlow AI utilizes a pooled database multi-tenant model with strict tenant isolation enforced at the database query and API layer:
- **Workspaces as Tenants:** Every customer account, team, or agency operates within one or more `Workspace` records.
- **Tenant Scope Identifier:** `workspace_id` (UUIDv4) is mandatory on all tenant-owned entities (`posts`, `campaigns`, `social_accounts`, `media_assets`, `notifications`, `audit_logs`).
- **Membership Binding:** `workspace_members` explicitly maps `user_id` to `workspace_id` along with an assigned role (`owner`, `admin`, `editor`, `approver`, `analyst`, `viewer`).

## 2. Workspace Switching (`POST /api/v1/workspaces/switch/{workspace_id}`)
1. Client requests workspace switch by passing target `workspace_id`.
2. Backend verifies caller holds an active membership record in that workspace (`status = "active"`).
3. If valid, the backend returns:
   - Target workspace profile (`name`, `slug`, `timezone`).
   - The user's role in that specific workspace.
   - The complete list of effective permissions granted in that workspace.
4. Client stores the active `workspace_id` and attaches it as `X-Workspace-ID` on subsequent API calls.
5. Cross-workspace access attempts without valid membership return `403 Forbidden` (`INSUFFICIENT_PERMISSIONS` or `WORKSPACE_ACCESS_DENIED`).

