from typing import Dict, List, Set

# Granular Permission Codes
ALL_PERMISSIONS: List[str] = [
    # Workspace Management
    "workspace.view",
    "workspace.update",
    "workspace.delete",
    "workspace.transfer_ownership",

    # Members & Team
    "members.view",
    "members.invite",
    "members.update_role",
    "members.remove",

    # Social Accounts
    "social_accounts.view",
    "social_accounts.connect",
    "social_accounts.disconnect",
    "social_accounts.manage",

    # Content & Posts
    "posts.view",
    "posts.create",
    "posts.update",
    "posts.delete",
    "posts.schedule",
    "posts.publish",

    # Approvals Workflow
    "approvals.view",
    "approvals.approve",
    "approvals.reject",
    "approvals.request_changes",

    # Media Library
    "media.view",
    "media.upload",
    "media.update",
    "media.delete",

    # Campaigns
    "campaigns.view",
    "campaigns.create",
    "campaigns.update",
    "campaigns.delete",

    # Analytics
    "analytics.view",
    "analytics.export",

    # Billing
    "billing.view",
    "billing.manage",
]

# Platform-Level Super Admin Permissions
PLATFORM_PERMISSIONS: List[str] = [
    "platform.users.manage",
    "platform.workspaces.manage",
    "platform.integrations.manage",
    "platform.system_logs.view",
]

# Static Role-to-Permissions Mapping for Workspace Roles
ROLE_PERMISSIONS_MAP: Dict[str, Set[str]] = {
    "owner": set(ALL_PERMISSIONS),

    "admin": {
        "workspace.view",
        "workspace.update",
        "members.view",
        "members.invite",
        "members.update_role",
        "members.remove",
        "social_accounts.view",
        "social_accounts.connect",
        "social_accounts.disconnect",
        "social_accounts.manage",
        "posts.view",
        "posts.create",
        "posts.update",
        "posts.delete",
        "posts.schedule",
        "posts.publish",
        "approvals.view",
        "approvals.approve",
        "approvals.reject",
        "approvals.request_changes",
        "media.view",
        "media.upload",
        "media.update",
        "media.delete",
        "campaigns.view",
        "campaigns.create",
        "campaigns.update",
        "campaigns.delete",
        "analytics.view",
        "analytics.export",
    },

    "editor": {
        "workspace.view",
        "social_accounts.view",
        "posts.view",
        "posts.create",
        "posts.update",
        "posts.delete",
        "posts.schedule",
        "media.view",
        "media.upload",
        "media.update",
        "media.delete",
        "campaigns.view",
        "analytics.view",
    },

    "approver": {
        "workspace.view",
        "posts.view",
        "approvals.view",
        "approvals.approve",
        "approvals.reject",
        "approvals.request_changes",
    },

    "analyst": {
        "workspace.view",
        "posts.view",
        "campaigns.view",
        "analytics.view",
        "analytics.export",
    },

    "viewer": {
        "workspace.view",
        "posts.view",
        "media.view",
        "campaigns.view",
        "analytics.view",
    },
}


def get_permissions_for_role(role: str) -> Set[str]:
    """Retrieve the set of allowed permissions for a given workspace role."""
    return ROLE_PERMISSIONS_MAP.get(role.lower(), set())


def has_permission(role: str, permission: str) -> bool:
    """Check if a workspace role includes a specific permission."""
    return permission in get_permissions_for_role(role)

