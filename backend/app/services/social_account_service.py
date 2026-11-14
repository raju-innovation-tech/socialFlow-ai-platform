from sqlalchemy.orm import Session
from app.core.exceptions import ConflictException, NotFoundException
from app.core.security import credential_vault
from app.models.social_account import SocialAccount, SocialAccountCredential
from app.repositories.social_account_repo import SocialAccountRepository
from app.schemas.social_account import SocialAccountCreate


class SocialAccountService:
    def __init__(self, db: Session):
        self.db = db
        self.repo = SocialAccountRepository(db)

    def list_accounts(self, workspace_id: str):
        return self.repo.list_by_workspace(workspace_id)

    def get_account(self, account_id: str) -> SocialAccount:
        acc = self.repo.get_by_id(account_id)
        if not acc:
            raise NotFoundException("SocialAccount", account_id)
        return acc

    def connect_account(self, data: SocialAccountCreate) -> SocialAccount:
        existing = self.repo.get_by_platform_account(
            data.workspace_id, data.platform, data.platform_account_id
        )
        if existing:
            raise ConflictException(
                f"Platform account '{data.platform_account_id}' is already connected to this workspace."
            )

        account = SocialAccount(
            workspace_id=data.workspace_id,
            platform=data.platform,
            account_name=data.account_name,
            platform_account_id=data.platform_account_id,
            account_type=data.account_type,
            profile_image_url=data.profile_image_url,
            connection_status="connected",
        )
        self.repo.create(account)

        # Encrypt & store credentials safely if provided
        if data.access_token:
            encrypted_token = credential_vault.encrypt(data.access_token)
            encrypted_refresh = credential_vault.encrypt(data.refresh_token) if data.refresh_token else None
            cred = SocialAccountCredential(
                account_id=account.id,
                encrypted_access_token=encrypted_token,
                encrypted_refresh_token=encrypted_refresh,
            )
            self.db.add(cred)
            self.db.commit()

        return account

    def disconnect_account(self, account_id: str) -> bool:
        account = self.get_account(account_id)
        return self.repo.delete(account)

