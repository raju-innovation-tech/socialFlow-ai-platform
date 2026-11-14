import base64
import hashlib
import secrets
import uuid
from datetime import datetime, timedelta, timezone
from typing import Any, Dict, Optional
import bcrypt
import jwt
from cryptography.fernet import Fernet
from app.core.config import settings
from app.core.exceptions import UnauthorizedException
from app.core.logging import logger


def hash_password(password: str) -> str:
    """Hash password using bcrypt with standard work factor."""
    salt = bcrypt.gensalt(rounds=12)
    return bcrypt.hashpw(password.encode("utf-8"), salt).decode("utf-8")


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verify plain password against hashed password."""
    if not plain_password or not hashed_password:
        return False
    try:
        return bcrypt.checkpw(plain_password.encode("utf-8"), hashed_password.encode("utf-8"))
    except Exception as e:
        logger.error("Error during password verification: %s", e)
        return False


def create_access_token(
    user_id: str,
    email: str,
    is_super_admin: bool = False,
    expires_delta: Optional[timedelta] = None,
) -> str:
    """Generate cryptographically signed short-lived JWT access token."""
    now = datetime.now(timezone.utc)
    if expires_delta:
        expire = now + expires_delta
    else:
        expire = now + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)

    payload: Dict[str, Any] = {
        "sub": user_id,
        "jti": str(uuid.uuid4()),
        "email": email,
        "is_super_admin": is_super_admin,
        "iat": int(now.timestamp()),
        "exp": int(expire.timestamp()),
        "iss": settings.JWT_ISSUER,
        "aud": settings.JWT_AUDIENCE,
    }

    return jwt.encode(payload, settings.SECRET_KEY, algorithm=settings.JWT_ALGORITHM)


def decode_access_token(token: str) -> Dict[str, Any]:
    """Decode and validate JWT access token claims."""
    try:
        payload = jwt.decode(
            token,
            settings.SECRET_KEY,
            algorithms=[settings.JWT_ALGORITHM],
            issuer=settings.JWT_ISSUER,
            audience=settings.JWT_AUDIENCE,
        )
        return payload
    except jwt.ExpiredSignatureError:
        raise UnauthorizedException("Access token has expired. Please refresh your session.")
    except jwt.InvalidTokenError as e:
        raise UnauthorizedException(f"Invalid access token: {str(e)}")


def generate_secure_token(nbytes: int = 32) -> str:
    """Generate high-entropy url-safe token for refresh tokens and reset links."""
    return secrets.token_urlsafe(nbytes)


def generate_numeric_otp(length: int = 6) -> str:
    """Generate cryptographically random numeric OTP."""
    digits = "0123456789"
    return "".join(secrets.choice(digits) for _ in range(length))


def hash_token(token: str) -> str:
    """Hash sensitive token (refresh token, reset token, OTP) with SHA-256 before storage."""
    return hashlib.sha256(token.encode("utf-8")).hexdigest()


class CredentialEncryption:
    """
    Symmetric encryption utility using Fernet (AES-128-CBC + HMAC-SHA256)
    for securely storing social account tokens and sensitive credentials.
    """

    def __init__(self, key: Optional[str] = None):
        raw_key = key or settings.ENCRYPTION_KEY
        try:
            key_bytes = raw_key.encode("utf-8")
            if len(key_bytes) == 32:
                self._fernet = Fernet(base64.urlsafe_b64encode(key_bytes))
            else:
                self._fernet = Fernet(key_bytes)
        except Exception as e:
            logger.warning("Deriving safe Fernet key from secret_key: %s", e)
            derived = hashlib.sha256((settings.SECRET_KEY + raw_key).encode("utf-8")).digest()
            self._fernet = Fernet(base64.urlsafe_b64encode(derived))

    def encrypt(self, plain_text: str) -> str:
        if not plain_text:
            return ""
        return self._fernet.encrypt(plain_text.encode("utf-8")).decode("utf-8")

    def decrypt(self, cipher_text: str) -> str:
        if not cipher_text:
            return ""
        return self._fernet.decrypt(cipher_text.encode("utf-8")).decode("utf-8")


credential_vault = CredentialEncryption()
