from typing import Callable, Optional
from fastapi import Depends, Request
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session
from app.core.config import settings
from app.core.database import get_db
from app.core.exceptions import ForbiddenException, NotFoundException, UnauthorizedException
from app.core.rbac import has_permission
from app.core.security import decode_access_token
from app.models.membership import WorkspaceMember
from app.models.user import User
from app.models.workspace import Workspace

oauth2_scheme = OAuth2PasswordBearer(
    tokenUrl=f"{settings.API_V1_PREFIX}/auth/login",
    auto_error=False,
)


def get_current_user(
    token: Optional[str] = Depends(oauth2_scheme),
    db: Session = Depends(get_db),
) -> User:
    """Validate JWT access token and return authenticated user."""
    if not token:
        raise UnauthorizedException("Authentication token required.")

    payload = decode_access_token(token)
    user_id = payload.get("sub")
    if not user_id:
        raise UnauthorizedException("Malformed access token claims.")

    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise UnauthorizedException("User account associated with this token does not exist.")

    return user


def get_current_active_user(
    current_user: User = Depends(get_current_user),
) -> User:
    """Ensure user account is active and verified."""
    if not current_user.is_active:
        raise ForbiddenException("User account has been deactivated.")
    if not current_user.email_verified and not current_user.is_super_admin:
        raise ForbiddenException("Email address has not been verified. Please complete OTP verification.")
    return current_user


def get_current_super_admin(
    current_user: User = Depends(get_current_active_user),
) -> User:
    """Ensure user has platform-level Super Admin role."""
    if not current_user.is_super_admin:
        raise ForbiddenException("Platform Super Admin privileges required.")
    return current_user


def get_active_workspace_member(
    request: Request,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
) -> WorkspaceMember:
    """
    Resolve and validate tenant isolation context.
    Extracts workspace_id from path parameters, 'X-Workspace-ID' header, or query parameters.
    Ensures that the authenticated user actually has an active membership in the target workspace.
    """
    target_workspace_id = (
        request.path_params.get("workspace_id")
        or request.headers.get("X-Workspace-ID")
        or request.headers.get("x-workspace-id")
        or request.query_params.get("workspace_id")
    )

    if not target_workspace_id:
        raise ForbiddenException("Workspace ID is required (via 'X-Workspace-ID' header or query parameter).")

    # Validate workspace exists and is active
    ws = db.query(Workspace).filter(Workspace.id == target_workspace_id).first()
    if not ws:
        raise NotFoundException("Workspace", target_workspace_id)
    if not ws.is_active:
        raise ForbiddenException("The requested workspace is suspended or inactive.")

    # Super Admin can manage any workspace
    if current_user.is_super_admin:
        member = db.query(WorkspaceMember).filter(
            WorkspaceMember.workspace_id == target_workspace_id,
            WorkspaceMember.user_id == current_user.id,
        ).first()
        if not member:
            member = WorkspaceMember(
                workspace_id=target_workspace_id,
                user_id=current_user.id,
                role="owner",
                status="active",
            )
        return member

    # Look up authenticated membership
    member = db.query(WorkspaceMember).filter(
        WorkspaceMember.workspace_id == target_workspace_id,
        WorkspaceMember.user_id == current_user.id,
        WorkspaceMember.status == "active",
    ).first()

    if not member:
        raise ForbiddenException(f"You do not have active membership in workspace '{target_workspace_id}'.")

    return member


def require_permission(permission_code: str) -> Callable:
    """
    Dependency factory checking that the active workspace member possesses the required permission.
    """
    def _permission_checker(
        member: WorkspaceMember = Depends(get_active_workspace_member),
    ) -> WorkspaceMember:
        if member.role == "owner":
            return member

        if not has_permission(member.role, permission_code):
            raise ForbiddenException(
                f"Your role ('{member.role}') lacks the required permission: '{permission_code}'"
            )
        return member

    return _permission_checker
