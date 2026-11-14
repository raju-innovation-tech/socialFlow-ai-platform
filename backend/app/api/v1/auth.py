from typing import List, Optional
from fastapi import APIRouter, Depends, Request, status
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.core.deps import get_current_active_user, get_current_user
from app.core.exceptions import NotFoundException
from app.models.auth_tokens import UserSession
from app.models.user import User
from app.schemas.auth import (
    AcceptInvitationRequest,
    AuthUserResponse,
    ChangePasswordRequest,
    ForgotPasswordRequest,
    LoginRequest,
    RefreshTokenRequest,
    RegisterRequest,
    ResetPasswordRequest,
    TokenResponse,
    UserSessionResponse,
    VerifyEmailRequest,
)
from app.services.auth_service import AuthService
from app.services.workspace_management_service import WorkspaceManagementService

router = APIRouter(prefix="/auth", tags=["Authentication"])


@router.post("/register", status_code=status.HTTP_201_CREATED)
def register_user(payload: RegisterRequest, request: Request, db: Session = Depends(get_db)):
    """Register a new user account with normalized email and issue verification OTP."""
    ip_address = request.client.host if request.client else None
    service = AuthService(db)
    user, otp_code = service.register(payload, ip_address=ip_address)

    return {
        "message": "Account created successfully. Please verify your email with the OTP code.",
        "user_id": user.id,
        "email": user.email,
        # OTP is returned in response for development / demo delivery
        "dev_verification_otp": otp_code,
    }


@router.post("/verify-email")
def verify_email(payload: VerifyEmailRequest, request: Request, db: Session = Depends(get_db)):
    """Verify account with 6-digit OTP code."""
    ip_address = request.client.host if request.client else None
    service = AuthService(db)
    service.verify_email(payload, ip_address=ip_address)
    return {"message": "Email verified successfully. You may now log in."}


@router.post("/resend-verification")
def resend_verification(email: str, db: Session = Depends(get_db)):
    """Resend a fresh verification OTP."""
    service = AuthService(db)
    otp_code = service.resend_verification(email)
    return {
        "message": "A new verification code has been generated.",
        "dev_verification_otp": otp_code,
    }


@router.post("/login", response_model=TokenResponse)
def login(payload: LoginRequest, request: Request, db: Session = Depends(get_db)):
    """Authenticate with email and password, returning short-lived JWT and rotating refresh token."""
    ip_address = request.client.host if request.client else None
    user_agent = request.headers.get("user-agent")
    service = AuthService(db)
    return service.login(payload, ip_address=ip_address, user_agent=user_agent)


@router.post("/refresh", response_model=TokenResponse)
def refresh_token(payload: RefreshTokenRequest, request: Request, db: Session = Depends(get_db)):
    """Exchange rotating refresh token for a new access token and new refresh token."""
    ip_address = request.client.host if request.client else None
    user_agent = request.headers.get("user-agent")
    service = AuthService(db)
    return service.refresh(payload.refresh_token, ip_address=ip_address, user_agent=user_agent)


@router.post("/logout", status_code=status.HTTP_200_OK)
def logout(
    payload: Optional[RefreshTokenRequest] = None,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Log out current session and revoke refresh token."""
    service = AuthService(db)
    service.logout(current_user.id, payload.refresh_token if payload else None)
    return {"message": "Logged out successfully."}


@router.post("/logout-all", status_code=status.HTTP_200_OK)
def logout_all(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Log out from all devices by terminating all active refresh tokens and sessions."""
    service = AuthService(db)
    service.logout_all(current_user.id)
    return {"message": "All sessions terminated successfully."}


@router.post("/forgot-password")
def forgot_password(payload: ForgotPasswordRequest, db: Session = Depends(get_db)):
    """Request password reset link/token."""
    service = AuthService(db)
    token = service.forgot_password(payload.email)
    return {
        "message": "If an account exists with this email, password reset instructions have been sent.",
        "dev_reset_token": token,
    }


@router.post("/reset-password")
def reset_password(payload: ResetPasswordRequest, db: Session = Depends(get_db)):
    """Reset password using secure token."""
    service = AuthService(db)
    service.reset_password(payload)
    return {"message": "Password reset successfully. You may now log in with your new password."}


@router.post("/change-password")
def change_password(
    payload: ChangePasswordRequest,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
):
    """Change password for authenticated user."""
    service = AuthService(db)
    service.change_password(current_user, payload)
    return {"message": "Password changed successfully."}


@router.get("/me")
def get_me(
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
):
    """Get authenticated user profile and authorized workspaces."""
    ws_service = WorkspaceManagementService(db)
    workspaces = ws_service.list_user_workspaces(current_user)

    return {
        "id": current_user.id,
        "email": current_user.email,
        "full_name": current_user.full_name,
        "is_active": current_user.is_active,
        "email_verified": current_user.email_verified,
        "is_super_admin": current_user.is_super_admin,
        "workspaces": workspaces,
    }


@router.get("/sessions", response_model=List[UserSessionResponse])
def list_sessions(
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
):
    """List active login sessions for user."""
    sessions = (
        db.query(UserSession)
        .filter(UserSession.user_id == current_user.id, UserSession.is_revoked == False)
        .order_by(UserSession.created_at.desc())
        .all()
    )
    return [
        UserSessionResponse(
            id=s.id,
            ip_address=s.ip_address,
            user_agent=s.user_agent,
            created_at=s.created_at,
            expires_at=s.expires_at,
        )
        for s in sessions
    ]


@router.delete("/sessions/{session_id}", status_code=status.HTTP_204_NO_CONTENT)
def revoke_session(
    session_id: str,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
):
    """Revoke a specific active session."""
    session = (
        db.query(UserSession)
        .filter(UserSession.id == session_id, UserSession.user_id == current_user.id)
        .first()
    )
    if not session:
        raise NotFoundException("UserSession", session_id)

    session.is_revoked = True
    if session.refresh_token:
        session.refresh_token.is_used = True
    db.commit()
    return None

