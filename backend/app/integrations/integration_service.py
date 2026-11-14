import secrets
from datetime import datetime, timedelta, timezone
from typing import Any, Dict, List, Optional, Tuple
from sqlalchemy.orm import Session

from app.core.exceptions import ConflictException, ForbiddenException, NotFoundException
from app.core.logging import logger
from app.integrations.base.capability_models import (
    AccountProfile,
    DiscoveredChannel,
    PlatformCapabilityModel,
)
from app.integrations.base.integration_exceptions import (
    OAuthStateInvalidException,
)
from app.integrations.base.token_manager import TokenManager
from app.integrations.registry import IntegrationRegistry
from app.models.audit_log import AuditLog
from app.models.social_account import (
    IntegrationSyncLog,
    OAuthState,
    SocialAccount,
    SocialAccountCredential,
    SocialAccountPermission,
)


class IntegrationService:
    def __init__(self, db: Session):
        self.db = db

    def generate_authorization_flow(
        self,
        workspace_id: str,
        platform: str,
        redirect_uri: Optional[str] = None,
    ) -> Dict[str, str]:
        """Generate official OAuth 2.0 URL with CSRF state protection & PKCE where supported."""
        provider = IntegrationRegistry.get_provider(platform)
        now = datetime.now(timezone.utc)

        state_token = secrets.token_urlsafe(32)
        code_verifier = secrets.token_urlsafe(48)  # For X / LinkedIn PKCE
        target_redirect = redirect_uri or "http://localhost:8001/api/v1/integrations/callback"

        # Persist OAuth State with 15-minute expiration
        oauth_state = OAuthState(
            state_token=state_token,
            workspace_id=workspace_id,
            platform=provider.platform_identifier,
            redirect_uri=target_redirect,
            code_verifier=code_verifier,
            expires_at=now + timedelta(minutes=15),
        )
        self.db.add(oauth_state)
        self.db.commit()

        auth_url = provider.get_authorization_url(
            workspace_id=workspace_id,
            redirect_uri=target_redirect,
            state_token=state_token,
            code_verifier=code_verifier,
        )

        return {
            "platform": provider.platform_identifier,
            "authorization_url": auth_url,
            "state": state_token,
        }

    async def handle_oauth_callback(
        self,
        code: str,
        state_token: str,
    ) -> Dict[str, Any]:
        """Validate state token, exchange code for tokens, fetch profile, and store securely."""
        now = datetime.now(timezone.utc)
        state_record = self.db.query(OAuthState).filter(
            OAuthState.state_token == state_token
        ).first()

        if not state_record:
            raise OAuthStateInvalidException("unknown", "OAuth state token is invalid or was not found.")

        # Ensure naive/aware comparison compatibility
        exp = state_record.expires_at
        if exp.tzinfo is None:
            exp = exp.replace(tzinfo=timezone.utc)

        if exp < now:
            self.db.delete(state_record)
            self.db.commit()
            raise OAuthStateInvalidException(state_record.platform, "OAuth state has expired. Please initiate connection again.")

        platform = state_record.platform
        workspace_id = state_record.workspace_id
        redirect_uri = state_record.redirect_uri
        code_verifier = state_record.code_verifier

        provider = IntegrationRegistry.get_provider(platform)

        # 1. Exchange authorization code for token bundle
        token_bundle = await provider.exchange_code_for_token(
            code=code,
            redirect_uri=redirect_uri,
            code_verifier=code_verifier,
        )

        # 2. Fetch authenticated user profile
        profile = await provider.fetch_profile(token_bundle.access_token)

        # 3. Check for sub-channels (Facebook Pages, Instagram Accounts, YouTube Channels)
        discovered_channels = await provider.discover_channels(token_bundle.access_token)

        # 4. Upsert SocialAccount in database
        account = self._upsert_account(
            workspace_id=workspace_id,
            platform=platform,
            profile=profile,
        )

        # 5. Encrypt credentials at rest
        TokenManager.encrypt_and_store(
            db=self.db,
            account_id=account.id,
            access_token=token_bundle.access_token,
            refresh_token=token_bundle.refresh_token,
            token_secret=token_bundle.token_secret,
            expires_in_seconds=token_bundle.expires_in,
        )

        # 6. Store granted permissions
        self._record_permissions(account.id, token_bundle.scopes)

        # 7. Audit log & cleanup state
        self._log_audit(
            workspace_id=workspace_id,
            action="account_connected",
            entity_id=account.id,
            metadata=f"Connected {platform} account: {account.account_name} ({account.platform_account_id})",
        )

        self.db.delete(state_record)
        self.db.commit()

        return {
            "account": account,
            "discovered_channels": discovered_channels,
            "message": f"Successfully connected {provider.platform_name} account.",
        }

    async def connect_discovered_page(
        self,
        workspace_id: str,
        platform: str,
        channel_id: str,
        channel_name: str,
        access_token: str,
        account_type: str = "page",
        avatar_url: Optional[str] = None,
    ) -> SocialAccount:
        """Connect a specific discovered page or channel selected by user."""
        profile = AccountProfile(
            platform_account_id=channel_id,
            username=channel_name,
            display_name=channel_name,
            account_type=account_type,
            profile_image_url=avatar_url,
            follower_count=0,
        )
        account = self._upsert_account(
            workspace_id=workspace_id,
            platform=platform,
            profile=profile,
        )
        TokenManager.encrypt_and_store(
            db=self.db,
            account_id=account.id,
            access_token=access_token,
            expires_in_seconds=5184000,
        )
        self._log_audit(
            workspace_id=workspace_id,
            action="subchannel_connected",
            entity_id=account.id,
            metadata=f"Connected {platform} sub-channel: {channel_name} ({channel_id})",
        )
        self.db.commit()
        return account

    async def connect_telegram(
        self,
        workspace_id: str,
        bot_token: str,
        chat_id: Optional[str] = None,
    ) -> SocialAccount:
        """Connect and validate Telegram bot and optionally verify channel admin permissions."""
        provider = IntegrationRegistry.get_provider("telegram")

        # 1. Validate Bot
        profile = await provider.fetch_profile(bot_token)

        # 2. If chat_id provided, verify bot is channel administrator
        chat_title = None
        if chat_id:
            from app.integrations.telegram.telegram_provider import TelegramProvider
            tg: TelegramProvider = provider  # type: ignore
            admin_check = await tg.validate_channel_admin(bot_token, chat_id)
            chat_title = admin_check.get("title")
            profile.metadata["chat_info"] = admin_check

        display_name = f"{profile.display_name} -> {chat_title}" if chat_title else profile.display_name
        platform_id = f"{profile.platform_account_id}_{chat_id}" if chat_id else profile.platform_account_id

        profile.display_name = display_name
        profile.platform_account_id = platform_id

        account = self._upsert_account(
            workspace_id=workspace_id,
            platform="telegram",
            profile=profile,
        )

        TokenManager.encrypt_and_store(
            db=self.db,
            account_id=account.id,
            access_token=bot_token,
        )

        self._log_audit(
            workspace_id=workspace_id,
            action="telegram_bot_connected",
            entity_id=account.id,
            metadata=f"Connected Telegram bot: {display_name}",
        )
        self.db.commit()
        return account

    async def sync_account(self, account_id: str, workspace_id: str) -> SocialAccount:
        """Refresh account metadata, followers count, and connection health."""
        account = self.db.query(SocialAccount).filter(
            SocialAccount.id == account_id,
            SocialAccount.workspace_id == workspace_id,
        ).first()

        if not account:
            raise NotFoundException("SocialAccount", account_id)

        access_token, refresh_token, _ = TokenManager.get_decrypted_tokens(self.db, account.id)
        if not access_token:
            account.connection_status = "expired"
            self.db.commit()
            raise ForbiddenException("Account credentials not found. Re-authorization required.")

        provider = IntegrationRegistry.get_provider(account.platform)
        try:
            profile = await provider.fetch_profile(access_token, account_id=account.platform_account_id)
            account.account_name = profile.display_name
            if profile.profile_image_url:
                account.profile_image_url = profile.profile_image_url
            account.follower_count = profile.follower_count
            account.connection_status = "connected"
            account.last_sync_at = datetime.now(timezone.utc)

            # Record sync log
            log = IntegrationSyncLog(
                account_id=account.id,
                sync_type="profile_sync",
                status="success",
                details=f"Followers: {profile.follower_count}, Status: connected",
            )
            self.db.add(log)
            self.db.commit()
            return account
        except Exception as e:
            account.connection_status = "error"
            log = IntegrationSyncLog(
                account_id=account.id,
                sync_type="profile_sync",
                status="failed",
                details=str(e),
            )
            self.db.add(log)
            self.db.commit()
            logger.error("Failed to sync account %s: %s", account.id, e)
            raise

    def get_capabilities(self, platform: Optional[str] = None) -> List[PlatformCapabilityModel]:
        """List platform capabilities across one or all platforms."""
        if platform:
            provider = IntegrationRegistry.get_provider(platform)
            return provider.get_capabilities()

        all_caps: List[PlatformCapabilityModel] = []
        for p in IntegrationRegistry.list_providers():
            all_caps.extend(p.get_capabilities())
        return all_caps

    def _upsert_account(
        self,
        workspace_id: str,
        platform: str,
        profile: AccountProfile,
    ) -> SocialAccount:
        existing = self.db.query(SocialAccount).filter(
            SocialAccount.workspace_id == workspace_id,
            SocialAccount.platform == platform,
            SocialAccount.platform_account_id == profile.platform_account_id,
        ).first()

        now = datetime.now(timezone.utc)
        if existing:
            existing.account_name = profile.display_name
            existing.profile_image_url = profile.profile_image_url or existing.profile_image_url
            existing.follower_count = profile.follower_count
            existing.connection_status = "connected"
            existing.last_sync_at = now
            return existing

        account = SocialAccount(
            workspace_id=workspace_id,
            platform=platform,
            account_name=profile.display_name,
            platform_account_id=profile.platform_account_id,
            account_type=profile.account_type,
            profile_image_url=profile.profile_image_url,
            follower_count=profile.follower_count,
            connection_status="connected",
            last_sync_at=now,
        )
        self.db.add(account)
        self.db.flush()
        return account

    def _record_permissions(self, account_id: str, scopes: List[str]):
        self.db.query(SocialAccountPermission).filter(
            SocialAccountPermission.account_id == account_id
        ).delete()
        for s in scopes:
            perm = SocialAccountPermission(
                account_id=account_id,
                scope=s,
                is_granted=True,
            )
            self.db.add(perm)

    def _log_audit(self, workspace_id: str, action: str, entity_id: str, metadata: str):
        try:
            log = AuditLog(
                workspace_id=workspace_id,
                action=action,
                entity_type="social_account",
                entity_id=entity_id,
                metadata_json=metadata,
            )
            self.db.add(log)
        except Exception:
            pass

