from sqlalchemy.orm import Session
from app.core.exceptions import NotFoundException
from app.models.campaign import Campaign
from app.repositories.campaign_repo import CampaignRepository
from app.schemas.campaign import CampaignCreate, CampaignUpdate


class CampaignService:
    def __init__(self, db: Session):
        self.db = db
        self.repo = CampaignRepository(db)

    def list_campaigns(self, workspace_id: str, skip: int = 0, limit: int = 50):
        return self.repo.list_by_workspace(workspace_id, skip=skip, limit=limit)

    def get_campaign(self, campaign_id: str) -> Campaign:
        c = self.repo.get_by_id(campaign_id)
        if not c:
            raise NotFoundException("Campaign", campaign_id)
        return c

    def create_campaign(self, data: CampaignCreate) -> Campaign:
        campaign = Campaign(
            workspace_id=data.workspace_id,
            name=data.name,
            description=data.description,
            start_date=data.start_date,
            end_date=data.end_date,
            budget_amount=data.budget_amount,
            budget_currency=data.budget_currency,
        )
        self.repo.create(campaign)

        if data.post_ids:
            for pid in data.post_ids:
                self.repo.link_post(campaign.id, pid)

        return campaign

    def update_campaign(self, campaign_id: str, data: CampaignUpdate) -> Campaign:
        c = self.get_campaign(campaign_id)
        return self.repo.update(c, data.model_dump(exclude_unset=True))

