from typing import List
from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.core.deps import require_permission
from app.core.exceptions import ForbiddenException
from app.models.membership import WorkspaceMember
from app.schemas.social_account import SocialAccountCreate, SocialAccountResponse
from app.services.social_account_service import SocialAccountService

router = APIRouter(prefix="/social-accounts", tags=["Social Accounts"])


@router.get("", response_model=List[SocialAccountResponse])
def list_social_accounts(
    member: WorkspaceMember = Depends(require_permission("social_accounts.view")),
    db: Session = Depends(get_db),
):
    """List connected social accounts strictly scoped to active workspace."""
    service = SocialAccountService(db)
    return service.list_accounts(member.workspace_id)


@router.post("", response_model=SocialAccountResponse, status_code=status.HTTP_201_CREATED)
def connect_social_account(
    payload: SocialAccountCreate,
    member: WorkspaceMember = Depends(require_permission("social_accounts.connect")),
    db: Session = Depends(get_db),
):
    """Connect a new social account within authenticated active workspace."""
    payload.workspace_id = member.workspace_id
    service = SocialAccountService(db)
    return service.connect_account(payload)


@router.get("/{account_id}", response_model=SocialAccountResponse)
def get_social_account(
    account_id: str,
    member: WorkspaceMember = Depends(require_permission("social_accounts.view")),
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
    member: WorkspaceMember = Depends(require_permission("social_accounts.disconnect")),
    db: Session = Depends(get_db),
):
    """Disconnect/remove social account with tenant check."""
    service = SocialAccountService(db)
    account = service.get_account(account_id)
    if account.workspace_id != member.workspace_id:
        raise ForbiddenException("Cross-tenant deletion prohibited.")
    service.disconnect_account(account_id)
    return None
