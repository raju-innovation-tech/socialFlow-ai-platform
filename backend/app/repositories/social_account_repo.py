from typing import List, Optional
from sqlalchemy.orm import Session
from app.models.social_account import SocialAccount, SocialPlatform, PlatformCapability
from app.repositories.base import BaseRepository


class SocialAccountRepository(BaseRepository[SocialAccount]):
    def __init__(self, db: Session):
        super().__init__(SocialAccount, db)

    def list_by_workspace(self, workspace_id: str) -> List[SocialAccount]:
        return (
            self.db.query(SocialAccount)
            .filter(SocialAccount.workspace_id == workspace_id)
            .order_by(SocialAccount.created_at.desc())
            .all()
        )

    def get_by_platform_account(self, workspace_id: str, platform: str, platform_account_id: str) -> Optional[SocialAccount]:
        return (
            self.db.query(SocialAccount)
            .filter(
                SocialAccount.workspace_id == workspace_id,
                SocialAccount.platform == platform,
                SocialAccount.platform_account_id == platform_account_id,
            )
            .first()
        )

    def get_platform_capabilities(self, platform_identifier: str) -> List[PlatformCapability]:
        return (
            self.db.query(PlatformCapability)
            .filter(PlatformCapability.platform_identifier == platform_identifier)
            .all()
        )

