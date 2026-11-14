import random
from datetime import datetime, timedelta, timezone
from typing import Optional


class RetryService:
    """Calculates exponential backoff delays with jitter for resilient publishing retries."""

    DEFAULT_BASE_DELAY_SECONDS = 30
    DEFAULT_MAX_DELAY_SECONDS = 3600  # 1 hour
    DEFAULT_MAX_RETRIES = 3

    @classmethod
    def calculate_next_retry(
        cls,
        attempt_number: int,
        base_delay: int = DEFAULT_BASE_DELAY_SECONDS,
        max_delay: int = DEFAULT_MAX_DELAY_SECONDS,
    ) -> datetime:
        """Calculate next retry timestamp using exponential backoff with full jitter."""
        # 2 ^ (attempt - 1) * base_delay
        exp_delay = base_delay * (2 ** max(0, attempt_number - 1))
        bounded_delay = min(max_delay, exp_delay)
        # Add random jitter between 0 and 20% of bounded delay
        jitter = random.uniform(0, bounded_delay * 0.2)
        total_delay = bounded_delay + jitter
        return datetime.now(timezone.utc) + timedelta(seconds=total_delay)

    @classmethod
    def is_eligible_for_retry(cls, attempt_number: int, max_retries: int = DEFAULT_MAX_RETRIES) -> bool:
        return attempt_number < max_retries

