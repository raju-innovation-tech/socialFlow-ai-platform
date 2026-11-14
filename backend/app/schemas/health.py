from typing import Dict, Optional
from pydantic import BaseModel, Field


class ServiceHealthResponse(BaseModel):
    status: str = Field(..., example="healthy")
    details: Optional[Dict[str, str]] = None


class SystemHealthResponse(BaseModel):
    app: str = "SocialFlow AI Backend"
    version: str = "0.2.0"
    environment: str = "development"
    status: str = "healthy"
    database: Dict[str, str]
    redis: Dict[str, str]

