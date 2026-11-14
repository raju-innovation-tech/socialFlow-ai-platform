from datetime import datetime
from typing import Optional
import httpx

from app.core.logging import logger
from app.models.social_account import SocialAccount
from app.analytics.providers.base import AccountMetricsData, BaseAnalyticsProvider, PostMetricsData


class InstagramAnalyticsProvider(BaseAnalyticsProvider):
    @property
    def platform_identifier(self) -> str:
        return "instagram"

    async def fetch_account_analytics(
        self,
        account: SocialAccount,
        decrypted_token: str,
        start_date: Optional[datetime] = None,
        end_date: Optional[datetime] = None,
    ) -> AccountMetricsData:
        ig_id = account.platform_account_id
        followers = account.follower_count or 0
        impressions = 0
        reach = 0

        try:
            async with self.create_http_client() as client:
                # 1. Fetch Follower count
                profile_url = f"https://graph.facebook.com/v20.0/{ig_id}?fields=followers_count,follows_count,media_count&access_token={decrypted_token}"
                p_res = await client.get(profile_url)
                if p_res.status_code == 200:
                    followers = p_res.json().get("followers_count", followers)

                # 2. Fetch User Insights
                ins_url = f"https://graph.facebook.com/v20.0/{ig_id}/insights?metric=impressions,reach&period=day&access_token={decrypted_token}"
                ins_res = await client.get(ins_url)
                if ins_res.status_code == 200:
                    data = ins_res.json().get("data", [])
                    for item in data:
                        name = item.get("name")
                        values = item.get("values", [])
                        val = sum(v.get("value", 0) for v in values) if values else 0
                        if name == "impressions":
                            impressions = val
                        elif name == "reach":
                            reach = val

                er = round((reach / followers * 100), 2) if followers > 0 else 0.0

                return AccountMetricsData(
                    platform="instagram",
                    account_id=account.id,
                    followers_count=followers,
                    impressions_count=impressions,
                    reach_count=reach,
                    engagement_rate=er,
                    metrics={"followers": followers, "impressions_day": impressions, "reach_day": reach},
                )
        except Exception as e:
            logger.warning("Instagram analytics fetch error for %s: %s", account.id, e)
            return AccountMetricsData(
                platform="instagram",
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
                url = f"https://graph.facebook.com/v20.0/{external_post_id}/insights?metric=likes,comments,saved,shares,reach&access_token={decrypted_token}"
                res = await client.get(url)
                if res.status_code == 200:
                    data = res.json().get("data", [])
                    metrics_map = {}
                    for item in data:
                        metrics_map[item.get("name")] = item.get("values", [{}])[0].get("value", 0)

                    return PostMetricsData(
                        post_id="",
                        external_post_id=external_post_id,
                        reach=metrics_map.get("reach", 0),
                        likes=metrics_map.get("likes", 0),
                        comments=metrics_map.get("comments", 0),
                        shares=metrics_map.get("shares", 0),
                        raw_metrics=metrics_map,
                    )
        except Exception as e:
            logger.warning("Instagram media analytics error for %s: %s", external_post_id, e)

        return PostMetricsData(post_id="", external_post_id=external_post_id)

