from datetime import datetime
from typing import Optional
import httpx

from app.core.logging import logger
from app.models.social_account import SocialAccount
from app.analytics.providers.base import AccountMetricsData, BaseAnalyticsProvider, PostMetricsData


class TelegramAnalyticsProvider(BaseAnalyticsProvider):
    @property
    def platform_identifier(self) -> str:
        return "telegram"

    async def fetch_account_analytics(
        self,
        account: SocialAccount,
        decrypted_token: str,
        start_date: Optional[datetime] = None,
        end_date: Optional[datetime] = None,
    ) -> AccountMetricsData:
        chat_id = account.platform_account_id
        followers = account.follower_count or 0

        if chat_id:
            try:
                async with self.create_http_client() as client:
                    url = f"https://api.telegram.org/bot{decrypted_token}/getChatMemberCount?chat_id={chat_id}"
                    res = await client.get(url)
                    if res.status_code == 200 and res.json().get("ok"):
                        followers = res.json().get("result", followers)
            except Exception as e:
                logger.warning("Telegram subscriber count fetch failed for %s: %s", account.id, e)

        return AccountMetricsData(
            platform="telegram",
            account_id=account.id,
            followers_count=followers,
            impressions_count=0,
            reach_count=0,
            engagement_rate=0.0,
            unsupported_metrics=["post_impressions", "message_reach"],
            metrics={
                "subscribers": followers,
                "notes": "Telegram Bot API does not provide message-level impression or reach analytics.",
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
            raw_metrics={"message_id": external_post_id, "note": "Post-level impressions unavailable via Bot API"},
        )

