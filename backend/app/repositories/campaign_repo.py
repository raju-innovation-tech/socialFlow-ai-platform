from typing import List
from sqlalchemy.orm import Session
from app.models.campaign import Campaign, CampaignPost
from app.repositories.base import BaseRepository


class CampaignRepository(BaseRepository[Campaign]):
    def __init__(self, db: Session):
        super().__init__(Campaign, db)

    def list_by_workspace(self, workspace_id: str, skip: int = 0, limit: int = 50) -> List[Campaign]:
        return (
            self.db.query(Campaign)
            .filter(Campaign.workspace_id == workspace_id)
            .order_by(Campaign.created_at.desc())
            .offset(skip)
            .limit(limit)
            .all()
        )

    def link_post(self, campaign_id: str, post_id: str) -> CampaignPost:
        link = CampaignPost(campaign_id=campaign_id, post_id=post_id)
        self.db.add(link)
        self.db.commit()
        return link

