from typing import Dict, List, Optional

from app.core.exceptions import NotFoundException
from app.integrations.base.base_provider import BasePlatformProvider
from app.integrations.facebook.facebook_provider import FacebookProvider
from app.integrations.instagram.instagram_provider import InstagramProvider
from app.integrations.linkedin.linkedin_provider import LinkedInProvider
from app.integrations.telegram.telegram_provider import TelegramProvider
from app.integrations.whatsapp.whatsapp_provider import WhatsAppProvider
from app.integrations.x.x_provider import XProvider
from app.integrations.youtube.youtube_provider import YouTubeProvider


class IntegrationRegistry:
    _providers: Dict[str, BasePlatformProvider] = {}

    @classmethod
    def register_defaults(cls):
        providers = [
            LinkedInProvider(),
            FacebookProvider(),
            InstagramProvider(),
            YouTubeProvider(),
            XProvider(),
            WhatsAppProvider(),
            TelegramProvider(),
        ]
        for p in providers:
            cls._providers[p.platform_identifier] = p

    @classmethod
    def get_provider(cls, platform: str) -> BasePlatformProvider:
        if not cls._providers:
            cls.register_defaults()
        provider = cls._providers.get(platform.lower())
        if not provider:
            raise NotFoundException("SocialPlatformProvider", platform)
        return provider

    @classmethod
    def list_providers(cls) -> List[BasePlatformProvider]:
        if not cls._providers:
            cls.register_defaults()
        return list(cls._providers.values())

