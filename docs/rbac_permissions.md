# Role-Based Access Control (RBAC) & Permissions

## 1. Workspace-Level Roles vs Super Admin Separation

```
                       ┌──────────────────────────────┐
                       │         SUPER ADMIN          │
                       │ Platform Developer / Operator│
                       └──────────────┬───────────────┘
                                      │ (Global System Access)
                                      ▼
                      ┌────────────────────────────────┐
                      │      Workspace-Level Roles     │
                      └────────────────────────────────┘
                                      │
          ┌───────────────┬───────────┴───┬──────────────┬──────────────┐
          ▼               ▼               ▼              ▼              ▼
      ┌───────┐       ┌───────┐       ┌────────┐    ┌─────────┐    ┌────────┐
      │ Owner │       │ Admin │       │ Editor │    │Approver │    │ Viewer │
      └───────┘       └───────┘       └────────┘    └─────────┘    └────────┘
                                                         │
                                                         ▼
                                                    ┌─────────┐
                                                    │ Analyst │
                                                    └─────────┘
```

> **Critical Security Invariant:**
> Super Admin is a global platform capability stored on `users.is_super_admin`, NEVER a workspace membership role. A workspace Admin can never elevate themselves or any team member to platform Super Admin.

## 2. Workspace Roles Matrix

| Role | Description | Key Permissions |
| :--- | :--- | :--- |
| **Owner** | Full workspace sovereignty, billing, transfer & deletion | All workspace permissions + billing + ownership transfer |
| **Admin** | Workspace operations & member management | Manage team, invite members, connect social channels, edit posts |
| **Editor** | Content drafting and scheduling | Create, edit, schedule posts, upload media assets |
| **Approver** | Content review and publishing gatekeeper | Approve or reject pending posts, view analytics |
| **Analyst** | Performance tracking and reporting | Read-only analytics, export reports, view posts |
| **Viewer** | Read-only oversight | View published posts, view media assets, view calendar |

## 3. Granular Permission Codes
- `workspace:manage`, `workspace:delete`, `workspace:transfer`
- `members:read`, `members:invite`, `members:update_role`, `members:remove`
- `posts:read`, `posts:create`, `posts:update`, `posts:delete`, `posts:publish`
- `posts:approve`, `posts:reject`
- `accounts:read`, `accounts:connect`, `accounts:disconnect`
- `media:read`, `media:upload`, `media:delete`
- `campaigns:read`, `campaigns:manage`
- `analytics:read`, `analytics:export`
- `billing:manage`

