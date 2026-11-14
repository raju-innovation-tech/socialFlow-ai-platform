# SocialFlow AI – Usage Metering & Quotas (Phase 7)

## 1. Unit Counting Definitions

To eliminate billing ambiguity, billable resources follow strict counting rules:
- **Connected Accounts**: Active social accounts linked to the workspace (`SocialAccount.connection_status == 'connected'`).
- **Team Members**: Accepted workspace memberships (`WorkspaceMember.status == 'active'`).
- **Monthly Publishing Targets**: Each individual social account target published during the active billing period. A parent post published to 3 accounts consumes **3 publishing targets**.
- **Media Storage**: Cumulative sum of `MediaAsset.file_size_bytes` divided by `1024 * 1024` for megabytes (MB).

---

## 2. Real-Time Telemetry Query

The usage endpoint (`GET /api/v1/billing/usage`) aggregates live database records:
```python
{
    "workspace_id": "ws-uuid",
    "plan_code": "pro",
    "plan_name": "Professional Plan",
    "status": "active",
    "billing_cycle": "monthly",
    "usage": {
        "connected_accounts": 7,
        "team_members": 3,
        "monthly_publishing": 48,
        "storage_mb": 14.2
    },
    "limits": {
        "max_social_accounts": 15,
        "max_team_members": 5,
        "monthly_published_targets": 500,
        "max_storage_mb": 25000,
        "analytics_history_days": 90,
        "export_enabled": true
    }
}
```

