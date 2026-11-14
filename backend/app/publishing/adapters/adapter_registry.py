from typing import Dict, Optional
from app.publishing.adapters.base import BasePublishingAdapter
from app.publishing.adapters.facebook_publisher import FacebookPublisher
from app.publishing.adapters.instagram_publisher import InstagramPublisher
from app.publishing.adapters.linkedin_publisher import LinkedInPublisher
from app.publishing.adapters.telegram_publisher import TelegramPublisher
from app.publishing.adapters.whatsapp_publisher import WhatsAppPublisher
from app.publishing.adapters.x_publisher import XPublisher
from app.publishing.adapters.youtube_publisher import YouTubePublisher


class PublishingAdapterRegistry:
    """Registry maintaining active publishing adapters for all 7 platforms."""

    def __init__(self):
        self._adapters: Dict[str, BasePublishingAdapter] = {}
        self._register_default_adapters()

    def _register_default_adapters(self):
        adapters = [
            LinkedInPublisher(),
            FacebookPublisher(),
            InstagramPublisher(),
            YouTubePublisher(),
            XPublisher(),
            WhatsAppPublisher(),
            TelegramPublisher(),
        ]
        for a in adapters:
            self._adapters[a.platform_identifier] = a
        # Register alias 'twitter' for 'x'
        self._adapters["twitter"] = self._adapters["x"]

    def get(self, platform: str) -> Optional[BasePublishingAdapter]:
        key = platform.strip().lower()
        return self._adapters.get(key)

    def is_supported(self, platform: str) -> bool:
        return platform.strip().lower() in self._adapters


publishing_registry = PublishingAdapterRegistry()

