import base64
import hashlib
from typing import Optional
from cryptography.fernet import Fernet
from app.core.config import settings
from app.core.logging import logger


class CredentialEncryption:
    """
    Symmetric encryption utility using Fernet (AES-128-CBC + HMAC-SHA256)
    for securely storing social account tokens and sensitive credentials.
    """

    def __init__(self, key: Optional[str] = None):
        raw_key = key or settings.ENCRYPTION_KEY
        try:
            # Ensure key is valid 32-byte base64 encoded
            key_bytes = raw_key.encode("utf-8")
            if len(key_bytes) == 32:
                # convert 32 raw bytes to urlsafe base64
                self._fernet = Fernet(base64.urlsafe_b64encode(key_bytes))
            else:
                self._fernet = Fernet(key_bytes)
        except Exception as e:
            logger.warning(
                "Configured ENCRYPTION_KEY is invalid for direct Fernet; deriving safe 32-byte key: %s",
                e,
            )
            # Derive deterministic safe Fernet key from secret_key + raw_key
            derived = hashlib.sha256((settings.SECRET_KEY + raw_key).encode("utf-8")).digest()
            self._fernet = Fernet(base64.urlsafe_b64encode(derived))

    def encrypt(self, plain_text: str) -> str:
        if not plain_text:
            return ""
        encrypted_bytes = self._fernet.encrypt(plain_text.encode("utf-8"))
        return encrypted_bytes.decode("utf-8")

    def decrypt(self, cipher_text: str) -> str:
        if not cipher_text:
            return ""
        decrypted_bytes = self._fernet.decrypt(cipher_text.encode("utf-8"))
        return decrypted_bytes.decode("utf-8")


credential_vault = CredentialEncryption()

