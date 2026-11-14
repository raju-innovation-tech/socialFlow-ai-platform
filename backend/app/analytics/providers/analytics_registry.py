from typing import Dict, Optional
from app.analytics.providers.base import BaseAnalyticsProvider
from app.analytics.providers.facebook_analytics import FacebookAnalyticsProvider
from app.analytics.providers.instagram_analytics import InstagramAnalyticsProvider
from app.analytics.providers.linkedin_analytics import LinkedInAnalyticsProvider
from app.analytics.providers.telegram_analytics import TelegramAnalyticsProvider
from app.analytics.providers.whatsapp_analytics import WhatsAppAnalyticsProvider
from app.analytics.providers.x_analytics import XAnalyticsProvider
from app.analytics.providers.youtube_analytics import YouTubeAnalyticsProvider


class AnalyticsProviderRegistry:
    """Registry maintaining active analytics providers for all 7 platforms."""

    def __init__(self):
        self._providers: Dict[str, BaseAnalyticsProvider] = {}
        self._register_default_providers()

    def _register_default_providers(self):
        providers = [
            LinkedInAnalyticsProvider(),
            FacebookAnalyticsProvider(),
            InstagramAnalyticsProvider(),
            YouTubeAnalyticsProvider(),
            XAnalyticsProvider(),
            WhatsAppAnalyticsProvider(),
            TelegramAnalyticsProvider(),
        ]
        for p in providers:
            self._providers[p.platform_identifier] = p
        self._providers["twitter"] = self._providers["x"]

    def get(self, platform: str) -> Optional[BaseAnalyticsProvider]:
        key = platform.strip().lower()
        return self._providers.get(key)

    def get_provider(self, platform: str) -> Optional[BaseAnalyticsProvider]:
        return self.get(platform)


analytics_registry = AnalyticsProviderRegistry()


def get_analytics_registry() -> AnalyticsProviderRegistry:
    return analytics_registry
