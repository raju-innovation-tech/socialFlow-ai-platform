from typing import Any, Dict, Optional
from fastapi import status
from app.core.exceptions import AppException


class IntegrationException(AppException):
    def __init__(
        self,
        detail: str,
        platform: str,
        error_code: str = "INTEGRATION_ERROR",
        status_code: int = status.HTTP_400_BAD_REQUEST,
        extra: Optional[Dict[str, Any]] = None,
    ):
        full_extra = {"platform": platform}
        if extra:
            full_extra.update(extra)
        super().__init__(status_code=status_code, error_code=error_code, detail=detail, extra=full_extra)


class OAuthStateInvalidException(IntegrationException):
    def __init__(self, platform: str, reason: str = "OAuth state is invalid or has expired."):
        super().__init__(
            detail=reason,
            platform=platform,
            error_code="OAUTH_STATE_INVALID",
            status_code=status.HTTP_400_BAD_REQUEST,
        )


class OAuthTokenExchangeException(IntegrationException):
    def __init__(self, platform: str, detail: str):
        super().__init__(
            detail=f"Token exchange failed: {detail}",
            platform=platform,
            error_code="TOKEN_EXCHANGE_FAILED",
            status_code=status.HTTP_401_UNAUTHORIZED,
        )


class AccountNotEligibleException(IntegrationException):
    def __init__(self, platform: str, reason: str):
        super().__init__(
            detail=f"Account not eligible for automation: {reason}",
            platform=platform,
            error_code="ACCOUNT_NOT_ELIGIBLE",
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        )


class PlatformRateLimitException(IntegrationException):
    def __init__(self, platform: str, retry_after: Optional[int] = None):
        super().__init__(
            detail=f"Platform API rate limit reached for {platform}.",
            platform=platform,
            error_code="PLATFORM_RATE_LIMITED",
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            extra={"retry_after": retry_after},
        )


class PlatformServiceUnavailableException(IntegrationException):
    def __init__(self, platform: str, detail: str = "Platform API endpoint is temporarily unreachable."):
        super().__init__(
            detail=detail,
            platform=platform,
            error_code="PLATFORM_UNAVAILABLE",
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
        )


class CapabilityRestrictedException(IntegrationException):
    def __init__(self, platform: str, capability: str, reason: str):
        super().__init__(
            detail=f"Capability '{capability}' is restricted on {platform}: {reason}",
            platform=platform,
            error_code="CAPABILITY_RESTRICTED",
            status_code=status.HTTP_403_FORBIDDEN,
            extra={"capability": capability, "restriction_reason": reason},
        )
