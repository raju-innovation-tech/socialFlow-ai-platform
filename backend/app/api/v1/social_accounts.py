from typing import Any, Dict, List
from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.core.deps import require_permission
from app.core.exceptions import ForbiddenException, NotFoundException
from app.integrations.integration_service import IntegrationService
from app.models.membership import WorkspaceMember
from app.models.social_account import SocialAccount, SocialAccountPermission
from app.schemas.social_account import (
    SocialAccountCreate,
    SocialAccountPermissionResponse,
    SocialAccountResponse,
)
from app.services.social_account_service import SocialAccountService

router = APIRouter(prefix="/social-accounts", tags=["Social Accounts"])


@router.get("", response_model=List[SocialAccountResponse])
def list_social_accounts(
    member: WorkspaceMember = Depends(require_permission("accounts:read")),
    db: Session = Depends(get_db),
):
    """List connected social accounts strictly scoped to active workspace."""
    service = SocialAccountService(db)
    return service.list_accounts(member.workspace_id)


@router.post("", response_model=SocialAccountResponse, status_code=status.HTTP_201_CREATED)
def connect_social_account(
    payload: SocialAccountCreate,
    member: WorkspaceMember = Depends(require_permission("accounts:connect")),
    db: Session = Depends(get_db),
):
    """Connect a new social account within authenticated active workspace."""
    payload.workspace_id = member.workspace_id
    service = SocialAccountService(db)
    return service.connect_account(payload)


@router.get("/{account_id}", response_model=SocialAccountResponse)
def get_social_account(
    account_id: str,
    member: WorkspaceMember = Depends(require_permission("accounts:read")),
    db: Session = Depends(get_db),
):
    """Get single social account details with tenant check."""
    service = SocialAccountService(db)
    account = service.get_account(account_id)
    if account.workspace_id != member.workspace_id:
        raise ForbiddenException("Cross-tenant access prohibited.")
    return account


@router.delete("/{account_id}", status_code=status.HTTP_204_NO_CONTENT)
def disconnect_social_account(
    account_id: str,
    member: WorkspaceMember = Depends(require_permission("accounts:disconnect")),
    db: Session = Depends(get_db),
):
    """Disconnect/remove social account with tenant check."""
    service = SocialAccountService(db)
    account = service.get_account(account_id)
    if account.workspace_id != member.workspace_id:
        raise ForbiddenException("Cross-tenant deletion prohibited.")
    service.disconnect_account(account_id)
    return None


@router.post("/{account_id}/sync", response_model=SocialAccountResponse)
async def sync_social_account(
    account_id: str,
    member: WorkspaceMember = Depends(require_permission("accounts:connect")),
    db: Session = Depends(get_db),
):
    """Refresh account profile, follower count, and token status from platform."""
    integration_service = IntegrationService(db)
    return await integration_service.sync_account(account_id=account_id, workspace_id=member.workspace_id)


@router.post("/{account_id}/reconnect")
def reconnect_social_account(
    account_id: str,
    member: WorkspaceMember = Depends(require_permission("accounts:connect")),
    db: Session = Depends(get_db),
):
    """Generate a re-authorization flow to refresh expired platform permissions."""
    account = db.query(SocialAccount).filter(
        SocialAccount.id == account_id,
        SocialAccount.workspace_id == member.workspace_id,
    ).first()
    if not account:
        raise NotFoundException("SocialAccount", account_id)

    integration_service = IntegrationService(db)
    return integration_service.generate_authorization_flow(
        workspace_id=member.workspace_id,
        platform=account.platform,
    )


@router.get("/{account_id}/permissions", response_model=List[SocialAccountPermissionResponse])
def get_account_permissions(
    account_id: str,
    member: WorkspaceMember = Depends(require_permission("accounts:read")),
    db: Session = Depends(get_db),
):
    """Get granular granted scopes and permissions for a connected account."""
    account = db.query(SocialAccount).filter(
        SocialAccount.id == account_id,
        SocialAccount.workspace_id == member.workspace_id,
    ).first()
    if not account:
        raise NotFoundException("SocialAccount", account_id)

    return db.query(SocialAccountPermission).filter(
        SocialAccountPermission.account_id == account_id
    ).all()

