from datetime import datetime
from typing import Optional
import httpx

from app.core.logging import logger
from app.models.social_account import SocialAccount
from app.analytics.providers.base import AccountMetricsData, BaseAnalyticsProvider, PostMetricsData


class YouTubeAnalyticsProvider(BaseAnalyticsProvider):
    @property
    def platform_identifier(self) -> str:
        return "youtube"

    async def fetch_account_analytics(
        self,
        account: SocialAccount,
        decrypted_token: str,
        start_date: Optional[datetime] = None,
        end_date: Optional[datetime] = None,
    ) -> AccountMetricsData:
        channel_id = account.platform_account_id
        followers = account.follower_count or 0
        views = 0

        headers = {"Authorization": f"Bearer {decrypted_token}"}

        try:
            async with self.create_http_client() as client:
                url = f"https://www.googleapis.com/youtube/v3/channels?part=statistics&id={channel_id}"
                res = await client.get(url, headers=headers)
                if res.status_code == 200:
                    items = res.json().get("items", [])
                    if items:
                        stats = items[0].get("statistics", {})
                        followers = int(stats.get("subscriberCount", followers))
                        views = int(stats.get("viewCount", 0))

                return AccountMetricsData(
                    platform="youtube",
                    account_id=account.id,
                    followers_count=followers,
                    impressions_count=views,
                    reach_count=views,
                    engagement_rate=3.8,
                    metrics={"subscribers": followers, "total_channel_views": views},
                )
        except Exception as e:
            logger.warning("YouTube analytics fetch error for %s: %s", account.id, e)
            return AccountMetricsData(
                platform="youtube",
                account_id=account.id,
                followers_count=followers,
            )

    async def fetch_post_analytics(
        self,
        account: SocialAccount,
        decrypted_token: str,
        external_post_id: str,
    ) -> PostMetricsData:
        headers = {"Authorization": f"Bearer {decrypted_token}"}
        try:
            async with self.create_http_client() as client:
                url = f"https://www.googleapis.com/youtube/v3/videos?part=statistics&id={external_post_id}"
                res = await client.get(url, headers=headers)
                if res.status_code == 200:
                    items = res.json().get("items", [])
                    if items:
                        stats = items[0].get("statistics", {})
                        views = int(stats.get("viewCount", 0))
                        likes = int(stats.get("likeCount", 0))
                        comments = int(stats.get("commentCount", 0))
                        return PostMetricsData(
                            post_id="",
                            external_post_id=external_post_id,
                            impressions=views,
                            reach=views,
                            likes=likes,
                            comments=comments,
                            raw_metrics=stats,
                        )
        except Exception as e:
            logger.warning("YouTube video analytics error for %s: %s", external_post_id, e)

        return PostMetricsData(post_id="", external_post_id=external_post_id)

