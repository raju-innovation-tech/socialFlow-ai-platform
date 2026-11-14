from typing import List, Optional
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.schemas.social_account import SocialAccountCreate, SocialAccountResponse
from app.services.social_account_service import SocialAccountService

router = APIRouter(prefix="/social-accounts", tags=["Social Accounts"])


@router.get("", response_model=List[SocialAccountResponse])
def list_social_accounts(
    workspace_id: str = Query(..., description="Workspace ID"),
    db: Session = Depends(get_db),
):
    """List connected social accounts for a workspace."""
    service = SocialAccountService(db)
    return service.list_accounts(workspace_id)


@router.post("", response_model=SocialAccountResponse, status_code=status.HTTP_201_CREATED)
def connect_social_account(payload: SocialAccountCreate, db: Session = Depends(get_db)):
    """Connect a new social account."""
    service = SocialAccountService(db)
    return service.connect_account(payload)


@router.get("/{account_id}", response_model=SocialAccountResponse)
def get_social_account(account_id: str, db: Session = Depends(get_db)):
    """Get single social account details."""
    service = SocialAccountService(db)
    return service.get_account(account_id)


@router.delete("/{account_id}", status_code=status.HTTP_204_NO_CONTENT)
def disconnect_social_account(account_id: str, db: Session = Depends(get_db)):
    """Disconnect/remove a social account."""
    service = SocialAccountService(db)
    service.disconnect_account(account_id)
    return None

