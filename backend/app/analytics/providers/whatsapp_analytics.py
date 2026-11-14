from datetime import datetime
from typing import Optional

from app.models.social_account import SocialAccount
from app.analytics.providers.base import AccountMetricsData, BaseAnalyticsProvider, PostMetricsData


class WhatsAppAnalyticsProvider(BaseAnalyticsProvider):
    @property
    def platform_identifier(self) -> str:
        return "whatsapp"

    async def fetch_account_analytics(
        self,
        account: SocialAccount,
        decrypted_token: str,
        start_date: Optional[datetime] = None,
        end_date: Optional[datetime] = None,
    ) -> AccountMetricsData:
        # WhatsApp Cloud API does not have public followers or feed impressions
        return AccountMetricsData(
            platform="whatsapp",
            account_id=account.id,
            followers_count=0,
            impressions_count=0,
            reach_count=0,
            engagement_rate=0.0,
            is_available=True,
            unsupported_metrics=["followers", "public_reach", "social_likes"],
            metrics={
                "messaging_type": "Meta WhatsApp Cloud API",
                "status": "connected",
                "notes": "Followers and feed impressions are officially unsupported for direct business messaging.",
            },
        )

    async def fetch_post_analytics(
        self,
        account: SocialAccount,
        decrypted_token: str,
        external_post_id: str,
    ) -> PostMetricsData:
        return PostMetricsData(
            post_id="",
            external_post_id=external_post_id,
            impressions=0,
            reach=0,
            likes=0,
            comments=0,
            shares=0,
            raw_metrics={"wamid": external_post_id, "channel": "whatsapp_direct_message"},
        )

