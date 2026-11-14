import json
import os
from typing import List, Union
from pydantic import Field, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

# Determine absolute path to root .env if present
_root_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
_root_env = os.path.join(_root_dir, ".env")
_active_env_file = _root_env if os.path.isfile(_root_env) else ".env"


class Settings(BaseSettings):
    # App Information
    APP_NAME: str = "SocialFlow AI"
    APP_ENV: str = "development"
    DEBUG: bool = True
    API_V1_PREFIX: str = "/api/v1"
    HOST: str = "0.0.0.0"
    PORT: int = 8001

    # Database Configuration
    DATABASE_URL: str = Field(
        default="postgresql://socialflow_user:socialflow_dev_password_change_in_prod@localhost:5434/socialflow_ai_db"
    )
    POSTGRES_POOL_SIZE: int = 10
    POSTGRES_MAX_OVERFLOW: int = 20
    POSTGRES_POOL_TIMEOUT: int = 30

    # Redis Configuration
    REDIS_URL: str = Field(default="redis://localhost:6380/0")
    REDIS_SOCKET_TIMEOUT: float = 3.0
    REDIS_MAX_CONNECTIONS: int = 15

    # Security Keys
    SECRET_KEY: str = "change_me_super_secret_signing_key_min_32_characters_for_socialflow"
    ENCRYPTION_KEY: str = "gx7Nso52XxQ_J9Lpk-Wp3d7BjGk6xxLKBikiyabOFd4="

    # JWT & Token Lifecycles
    JWT_ALGORITHM: str = "HS256"
    JWT_ISSUER: str = "socialflow-ai"
    JWT_AUDIENCE: str = "socialflow-client"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 15
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7
    OTP_EXPIRE_MINUTES: int = 10
    OTP_MAX_ATTEMPTS: int = 3
    PASSWORD_RESET_EXPIRE_MINUTES: int = 15

    # CORS Configuration
    CORS_ORIGINS: Union[List[str], str] = ["*"]

    @field_validator("CORS_ORIGINS", mode="before")
    @classmethod
    def assemble_cors_origins(cls, v: Union[str, List[str]]) -> List[str]:
        if isinstance(v, str):
            if v.startswith("[") and v.endswith("]"):
                try:
                    return json.loads(v)
                except json.JSONDecodeError:
                    return [i.strip() for i in v[1:-1].split(",")]
            return [i.strip() for i in v.split(",") if i.strip()]
        elif isinstance(v, list):
            return v
        return ["*"]

    # Media Storage
    LOCAL_MEDIA_DIR: str = "./backend/uploads"
    MAX_UPLOAD_SIZE_MB: int = 25
    ALLOWED_MIME_TYPES: List[str] = [
        "image/jpeg",
        "image/png",
        "image/webp",
        "image/gif",
        "video/mp4",
        "video/quicktime",
        "application/pdf",
    ]

    # Platform Integration & OAuth Settings
    API_BASE_URL: str = "http://localhost:8001"
    FRONTEND_BASE_URL: str = "http://localhost:3000"
    
    LINKEDIN_CLIENT_ID: str = ""
    LINKEDIN_CLIENT_SECRET: str = ""
    LINKEDIN_REDIRECT_URI: str = "http://localhost:8001/api/v1/integrations/linkedin/callback"

    META_APP_ID: str = ""
    META_APP_SECRET: str = ""
    META_REDIRECT_URI: str = "http://localhost:8001/api/v1/integrations/facebook/callback"

    GOOGLE_CLIENT_ID: str = ""
    GOOGLE_CLIENT_SECRET: str = ""
    GOOGLE_REDIRECT_URI: str = "http://localhost:8001/api/v1/integrations/youtube/callback"

    X_CLIENT_ID: str = ""
    X_CLIENT_SECRET: str = ""
    X_REDIRECT_URI: str = "http://localhost:8001/api/v1/integrations/x/callback"

    WHATSAPP_API_VERSION: str = "v20.0"
    WHATSAPP_WEBHOOK_VERIFY_TOKEN: str = "socialflow_whatsapp_webhook_verify_secret_2026"

    TELEGRAM_WEBHOOK_SECRET: str = "socialflow_telegram_webhook_secret_2026"

    # Logging
    LOG_LEVEL: str = "INFO"

    model_config = SettingsConfigDict(
        env_file=_active_env_file,
        env_file_encoding="utf-8",
        case_sensitive=True,
        extra="ignore",
    )


settings = Settings()
