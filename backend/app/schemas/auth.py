from datetime import datetime
from typing import List, Optional
from pydantic import BaseModel, EmailStr, Field, field_validator


class RegisterRequest(BaseModel):
    full_name: str = Field(..., min_length=2, max_length=255)
    email: EmailStr
    password: str = Field(..., min_length=8, max_length=128)
    confirm_password: str = Field(..., min_length=8, max_length=128)
    terms_accepted: bool = Field(..., description="Must accept terms and privacy policy")

    @field_validator("confirm_password")
    @classmethod
    def passwords_match(cls, v: str, info):
        if "password" in info.data and v != info.data["password"]:
            raise ValueError("Passwords do not match")
        return v

    @field_validator("terms_accepted")
    @classmethod
    def terms_must_be_accepted(cls, v: bool):
        if not v:
            raise ValueError("You must accept the terms and conditions")
        return v


class VerifyEmailRequest(BaseModel):
    email: EmailStr
    otp: str = Field(..., min_length=6, max_length=6)


class ResendVerificationRequest(BaseModel):
    email: EmailStr


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class AuthUserResponse(BaseModel):
    id: str
    email: str
    full_name: str
    is_active: bool
    email_verified: bool
    is_super_admin: bool
    default_workspace_id: Optional[str] = None


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int
    user: AuthUserResponse


class RefreshTokenRequest(BaseModel):
    refresh_token: str


class ForgotPasswordRequest(BaseModel):
    email: EmailStr


class ResetPasswordRequest(BaseModel):
    token: str
    new_password: str = Field(..., min_length=8, max_length=128)
    confirm_password: str = Field(..., min_length=8, max_length=128)

    @field_validator("confirm_password")
    @classmethod
    def passwords_match(cls, v: str, info):
        if "new_password" in info.data and v != info.data["new_password"]:
            raise ValueError("Passwords do not match")
        return v


class ChangePasswordRequest(BaseModel):
    current_password: str
    new_password: str = Field(..., min_length=8, max_length=128)
    confirm_password: str = Field(..., min_length=8, max_length=128)

    @field_validator("confirm_password")
    @classmethod
    def passwords_match(cls, v: str, info):
        if "new_password" in info.data and v != info.data["new_password"]:
            raise ValueError("Passwords do not match")
        return v


class UserSessionResponse(BaseModel):
    id: str
    ip_address: Optional[str] = None
    user_agent: Optional[str] = None
    created_at: datetime
    expires_at: datetime
    is_current: bool = False


class WorkspaceMemberDetailResponse(BaseModel):
    id: str
    workspace_id: str
    user_id: str
    email: str
    full_name: str
    role: str
    status: str
    joined_at: datetime


class InviteMemberRequest(BaseModel):
    email: EmailStr
    role: str = Field("editor", pattern="^(admin|editor|approver|analyst|viewer)$")


class InvitationResponse(BaseModel):
    id: str
    workspace_id: str
    email: str
    role: str
    status: str
    expires_at: datetime
    created_at: datetime


class AcceptInvitationRequest(BaseModel):
    token: str


class UpdateMemberRoleRequest(BaseModel):
    role: str = Field(..., pattern="^(admin|editor|approver|analyst|viewer)$")


class TransferOwnershipRequest(BaseModel):
    new_owner_user_id: str


class SwitchWorkspaceResponse(BaseModel):
    workspace_id: str
    workspace_name: str
    workspace_slug: str
    role: str
    permissions: List[str]

