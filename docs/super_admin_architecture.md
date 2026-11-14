# SocialFlow AI – Super Admin Architecture (Phase 7)

## 1. Role Separation: Workspace vs Platform

```
+--------------------------------------------------------------+
|                    PLATFORM SUPER ADMIN                      |
|                (Platform Developer / Operator)               |
+--------------------------------------------------------------+
                                |
                                v
+--------------------------------------------------------------+
|                     WORKSPACE-LEVEL ROLES                    |
|   Owner     Admin     Editor     Approver   Analyst   Viewer |
+--------------------------------------------------------------+
```

### Essential Security Invariant
Super Admin is **NOT** a workspace role. A Workspace Admin or Owner cannot promote themselves or anyone else to Super Admin. Platform Super Admin privileges are stored strictly on `users.is_super_admin` and enforced by `get_current_super_admin`.

---

## 2. Super Admin Control Panel Modules

Matching the conceptual design preview:
1. **User Management**: View all users, search, filter by status, suspend account, reactivate account.
2. **Workspace Management**: View all multi-tenant workspaces, inspect owners and subscriptions, suspend, reactivate.
3. **Payments & Refunds**: Platform-wide transaction history and gateway refund dispatch.
4. **Plan Management**: Create, edit, activate, deactivate subscription plans and price tiers.
5. **System Monitoring**: Live health of PostgreSQL, Redis, Celery workers, and 7 social platform integrations.
6. **Audit Logs**: Immutable log trail of administrative operations.

---

## 3. Super Admin CLI Bootstrap

To promote a platform administrator safely without a public registration endpoint:
```powershell
python -m app.admin.scripts.bootstrap_super_admin --email admin@socialflow.ai
```

