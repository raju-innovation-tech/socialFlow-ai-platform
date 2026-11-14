from fastapi import APIRouter
from app.api.v1 import (
    admin,
    analytics,
    auth,
    billing,
    campaigns,
    health,
    integrations,
    invitations,
    media,
    notifications,
    posts,
    social_accounts,
    teams,
    users,
    workspaces,
)

api_v1_router = APIRouter()

# Register all v1 modules
api_v1_router.include_router(health.router)
api_v1_router.include_router(auth.router)
api_v1_router.include_router(invitations.router)
api_v1_router.include_router(integrations.router)
api_v1_router.include_router(workspaces.router)
api_v1_router.include_router(admin.router)
api_v1_router.include_router(users.router)
api_v1_router.include_router(social_accounts.router)
api_v1_router.include_router(posts.router)
api_v1_router.include_router(media.router)
api_v1_router.include_router(campaigns.router)
api_v1_router.include_router(analytics.router)
api_v1_router.include_router(notifications.router)
api_v1_router.include_router(teams.router)
api_v1_router.include_router(billing.router)
