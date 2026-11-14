import threading
from datetime import datetime, timedelta, timezone
from typing import Optional, Tuple
from sqlalchemy.orm import Session

from app.core.security import credential_vault
from app.models.social_account import SocialAccountCredential


class TokenManager:
    _lock = threading.Lock()

    @staticmethod
    def encrypt_and_store(
        db: Session,
        account_id: str,
        access_token: str,
        refresh_token: Optional[str] = None,
        token_secret: Optional[str] = None,
        expires_in_seconds: Optional[int] = None,
    ) -> SocialAccountCredential:
        """Encrypt sensitive credentials at rest and upsert in database."""
        encrypted_access = credential_vault.encrypt(access_token)
        encrypted_refresh = credential_vault.encrypt(refresh_token) if refresh_token else None
        encrypted_secret = credential_vault.encrypt(token_secret) if token_secret else None

        expires_at = None
        if expires_in_seconds and expires_in_seconds > 0:
            expires_at = datetime.now(timezone.utc) + timedelta(seconds=expires_in_seconds)

        existing = db.query(SocialAccountCredential).filter(
            SocialAccountCredential.account_id == account_id
        ).first()

        if existing:
            existing.encrypted_access_token = encrypted_access
            if encrypted_refresh:
                existing.encrypted_refresh_token = encrypted_refresh
            if encrypted_secret:
                existing.encrypted_token_secret = encrypted_secret
            existing.token_expires_at = expires_at
            cred = existing
        else:
            cred = SocialAccountCredential(
                account_id=account_id,
                encrypted_access_token=encrypted_access,
                encrypted_refresh_token=encrypted_refresh,
                encrypted_token_secret=encrypted_secret,
                token_expires_at=expires_at,
                encryption_algorithm="fernet-aes128-cbc",
            )
            db.add(cred)

        db.flush()
        return cred

    @staticmethod
    def get_decrypted_tokens(
        db: Session, account_id: str
    ) -> Tuple[Optional[str], Optional[str], Optional[str]]:
        """Retrieve and decrypt access token, refresh token and secret."""
        cred = db.query(SocialAccountCredential).filter(
            SocialAccountCredential.account_id == account_id
        ).first()

        if not cred:
            return None, None, None

        access = credential_vault.decrypt(cred.encrypted_access_token)
        refresh = credential_vault.decrypt(cred.encrypted_refresh_token) if cred.encrypted_refresh_token else None
        secret = credential_vault.decrypt(cred.encrypted_token_secret) if cred.encrypted_token_secret else None

        return access, refresh, secret
