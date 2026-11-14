from datetime import datetime
from typing import Optional
import httpx

from app.core.logging import logger
from app.models.social_account import SocialAccount
from app.analytics.providers.base import AccountMetricsData, BaseAnalyticsProvider, PostMetricsData


class FacebookAnalyticsProvider(BaseAnalyticsProvider):
    @property
    def platform_identifier(self) -> str:
        return "facebook"

    async def fetch_account_analytics(
        self,
        account: SocialAccount,
        decrypted_token: str,
        start_date: Optional[datetime] = None,
        end_date: Optional[datetime] = None,
    ) -> AccountMetricsData:
        page_id = account.platform_account_id
        followers = account.follower_count or 0
        impressions = 0
        reach = 0

        try:
            async with self.create_http_client() as client:
                # 1. Fetch Fan/Follower Count
                fan_url = f"https://graph.facebook.com/v20.0/{page_id}?fields=followers_count,fan_count&access_token={decrypted_token}"
                fan_res = await client.get(fan_url)
                if fan_res.status_code == 200:
                    fan_data = fan_res.json()
                    followers = fan_data.get("followers_count") or fan_data.get("fan_count", followers)

                # 2. Fetch Page Insights
                insights_url = f"https://graph.facebook.com/v20.0/{page_id}/insights?metric=page_impressions,page_post_engagements&period=days_28&access_token={decrypted_token}"
                ins_res = await client.get(insights_url)
                if ins_res.status_code == 200:
                    data = ins_res.json().get("data", [])
                    for item in data:
                        name = item.get("name")
                        values = item.get("values", [])
                        val = values[-1].get("value", 0) if values else 0
                        if name == "page_impressions":
                            impressions = val
                        elif name == "page_post_engagements":
                            reach = val

                er = round((reach / impressions * 100), 2) if impressions > 0 else 0.0

                return AccountMetricsData(
                    platform="facebook",
                    account_id=account.id,
                    followers_count=followers,
                    impressions_count=impressions,
                    reach_count=reach,
                    engagement_rate=er,
                    metrics={"followers": followers, "impressions_28d": impressions, "engagements_28d": reach},
                )
        except Exception as e:
            logger.warning("Facebook analytics fetch error for %s: %s", account.id, e)
            return AccountMetricsData(
                platform="facebook",
                account_id=account.id,
                followers_count=followers,
            )

    async def fetch_post_analytics(
        self,
        account: SocialAccount,
        decrypted_token: str,
        external_post_id: str,
    ) -> PostMetricsData:
        try:
            async with self.create_http_client() as client:
                url = f"https://graph.facebook.com/v20.0/{external_post_id}?fields=reactions.summary(true),comments.summary(true),shares&access_token={decrypted_token}"
                res = await client.get(url)
                if res.status_code == 200:
                    data = res.json()
                    likes = data.get("reactions", {}).get("summary", {}).get("total_count", 0)
                    comments = data.get("comments", {}).get("summary", {}).get("total_count", 0)
                    shares = data.get("shares", {}).get("count", 0)
                    return PostMetricsData(
                        post_id="",
                        external_post_id=external_post_id,
                        likes=likes,
                        comments=comments,
                        shares=shares,
                        raw_metrics=data,
                    )
        except Exception as e:
            logger.warning("Facebook post analytics error for %s: %s", external_post_id, e)

        return PostMetricsData(post_id="", external_post_id=external_post_id)

