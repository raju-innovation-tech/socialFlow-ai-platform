import uuid
from typing import Any, Dict, List
from fastapi import APIRouter, Depends, status
from slugify import slugify
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.core.deps import (
    get_active_workspace_member,
    get_current_active_user,
    require_permission,
)
from app.core.exceptions import ConflictException, ForbiddenException, NotFoundException
from app.core.rbac import ROLE_PERMISSIONS_MAP, get_permissions_for_role
from app.models.membership import WorkspaceInvitation, WorkspaceMember
from app.models.user import User
from app.models.workspace import Workspace
from app.schemas.auth import (
    InviteMemberRequest,
    SwitchWorkspaceResponse,
    TransferOwnershipRequest,
    UpdateMemberRoleRequest,
    WorkspaceMemberDetailResponse,
)
from app.schemas.workspace import WorkspaceCreate, WorkspaceResponse, WorkspaceUpdate
from app.services.workspace_management_service import WorkspaceManagementService

router = APIRouter(prefix="/workspaces", tags=["Workspaces"])


@router.get("", response_model=List[Dict[str, Any]])
def list_my_workspaces(
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
):
    """List all workspaces where authenticated user has active membership."""
    service = WorkspaceManagementService(db)
    return service.list_user_workspaces(current_user)


@router.post("", response_model=WorkspaceResponse, status_code=status.HTTP_201_CREATED)
def create_workspace(
    payload: WorkspaceCreate,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
):
    """Create a new workspace. Authenticated creator automatically becomes the Owner."""
    if payload.slug:
        existing_slug = db.query(Workspace).filter(Workspace.slug == payload.slug).first()
        if existing_slug:
            raise ConflictException(f"Workspace with slug '{payload.slug}' already exists.")
        slug_base = payload.slug
    else:
        slug_base = slugify(payload.name)
        existing_slug = db.query(Workspace).filter(Workspace.slug == slug_base).first()
        if existing_slug:
            slug_base = f"{slug_base}-{uuid.uuid4().hex[:6]}"

    workspace = Workspace(
        name=payload.name,
        slug=slug_base,
        description=payload.description,
        logo_url=payload.logo_url,
        owner_id=current_user.id,
        status="active",
        is_active=True,
    )
    db.add(workspace)
    db.flush()

    # Create Owner membership
    membership = WorkspaceMember(
        workspace_id=workspace.id,
        user_id=current_user.id,
        role="owner",
        status="active",
    )
    db.add(membership)
    db.commit()
    db.refresh(workspace)

    return workspace


@router.get("/{workspace_id}", response_model=WorkspaceResponse)
def get_workspace(
    workspace_id: str,
    member: WorkspaceMember = Depends(require_permission("workspace.view")),
    db: Session = Depends(get_db),
):
    """Get single workspace metadata (requires membership)."""
    ws = db.query(Workspace).filter(Workspace.id == workspace_id).first()
    if not ws:
        raise NotFoundException("Workspace", workspace_id)
    return ws


@router.patch("/{workspace_id}", response_model=WorkspaceResponse)
def update_workspace(
    workspace_id: str,
    payload: WorkspaceUpdate,
    member: WorkspaceMember = Depends(require_permission("workspace.update")),
    db: Session = Depends(get_db),
):
    """Update workspace details (requires 'workspace.update' permission)."""
    ws = db.query(Workspace).filter(Workspace.id == workspace_id).first()
    if not ws:
        raise NotFoundException("Workspace", workspace_id)

    update_data = payload.model_dump(exclude_unset=True)
    for field, val in update_data.items():
        if hasattr(ws, field) and val is not None:
            setattr(ws, field, val)

    db.commit()
    db.refresh(ws)
    return ws


@router.post("/{workspace_id}/switch", response_model=SwitchWorkspaceResponse)
def switch_workspace(
    workspace_id: str,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
):
    """Switch active workspace. Validates membership and returns permissions."""
    service = WorkspaceManagementService(db)
    return service.switch_workspace(current_user, workspace_id)


@router.post("/{workspace_id}/transfer-ownership")
def transfer_ownership(
    workspace_id: str,
    payload: TransferOwnershipRequest,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
):
    """Transfer workspace ownership to another active member (Owner only)."""
    service = WorkspaceManagementService(db)
    service.transfer_ownership(workspace_id, payload.new_owner_user_id, current_user)
    return {"message": "Workspace ownership transferred successfully."}


# Workspace Members Sub-Resource
@router.get("/{workspace_id}/members", response_model=List[WorkspaceMemberDetailResponse])
def list_workspace_members(
    workspace_id: str,
    member: WorkspaceMember = Depends(require_permission("members.view")),
    db: Session = Depends(get_db),
):
    """List members and their roles in the workspace."""
    service = WorkspaceManagementService(db)
    return service.list_members(workspace_id)


@router.post("/{workspace_id}/invitations", status_code=status.HTTP_201_CREATED)
def invite_member(
    workspace_id: str,
    payload: InviteMemberRequest,
    current_user: User = Depends(get_current_active_user),
    member: WorkspaceMember = Depends(require_permission("members.invite")),
    db: Session = Depends(get_db),
):
    """Invite a new member by email with an assigned workspace role."""
    service = WorkspaceManagementService(db)
    invitation = service.invite_member(workspace_id, current_user, payload)
    return {
        "message": f"Invitation created for {invitation.email}",
        "invitation_id": invitation.id,
        "role": invitation.role,
        "dev_invitation_token": invitation.token,
    }


@router.get("/{workspace_id}/invitations")
def list_workspace_invitations(
    workspace_id: str,
    member: WorkspaceMember = Depends(require_permission("members.view")),
    db: Session = Depends(get_db),
):
    """List pending invitations for the workspace."""
    invitations = (
        db.query(WorkspaceInvitation)
        .filter(WorkspaceInvitation.workspace_id == workspace_id, WorkspaceInvitation.status == "pending")
        .all()
    )
    return [
        {
            "id": inv.id,
            "email": inv.email,
            "role": inv.role,
            "status": inv.status,
            "expires_at": inv.expires_at.isoformat(),
            "created_at": inv.created_at.isoformat(),
        }
        for inv in invitations
    ]


@router.delete("/{workspace_id}/invitations/{invitation_id}", status_code=status.HTTP_204_NO_CONTENT)
def cancel_invitation(
    workspace_id: str,
    invitation_id: str,
    current_user: User = Depends(get_current_active_user),
    member: WorkspaceMember = Depends(require_permission("members.invite")),
    db: Session = Depends(get_db),
):
    """Cancel a pending invitation."""
    service = WorkspaceManagementService(db)
    service.cancel_invitation(workspace_id, invitation_id, current_user)
    return None


@router.patch("/{workspace_id}/members/{member_id}/role", response_model=WorkspaceMemberDetailResponse)
def update_member_role(
    workspace_id: str,
    member_id: str,
    payload: UpdateMemberRoleRequest,
    current_user: User = Depends(get_current_active_user),
    member: WorkspaceMember = Depends(require_permission("members.update_role")),
    db: Session = Depends(get_db),
):
    """Update a team member's workspace role."""
    service = WorkspaceManagementService(db)
    updated = service.update_member_role(workspace_id, member_id, payload.role, current_user)
    return WorkspaceMemberDetailResponse(
        id=updated.id,
        workspace_id=updated.workspace_id,
        user_id=updated.user_id,
        email=updated.user.email,
        full_name=updated.user.full_name,
        role=updated.role,
        status=updated.status,
        joined_at=updated.joined_at,
    )


@router.delete("/{workspace_id}/members/{member_id}", status_code=status.HTTP_204_NO_CONTENT)
def remove_member(
    workspace_id: str,
    member_id: str,
    current_user: User = Depends(get_current_active_user),
    member: WorkspaceMember = Depends(require_permission("members.remove")),
    db: Session = Depends(get_db),
):
    """Remove a member from the workspace."""
    service = WorkspaceManagementService(db)
    service.remove_member(workspace_id, member_id, current_user)
    return None


# Roles & Permissions Endpoints
@router.get("/{workspace_id}/roles")
def list_workspace_roles(
    workspace_id: str,
    member: WorkspaceMember = Depends(require_permission("workspace.view")),
):
    """List available roles and descriptions in the workspace."""
    return [
        {"role": "owner", "description": "Full access to workspace management, billing, settings and deletion."},
        {"role": "admin", "description": "Manage members, accounts, settings and content operations."},
        {"role": "editor", "description": "Create, edit and schedule posts and upload media."},
        {"role": "approver", "description": "Review, approve and reject queued content."},
        {"role": "analyst", "description": "Access performance metrics and generate reports."},
        {"role": "viewer", "description": "Read-only access to dashboard and published posts."},
    ]


@router.get("/{workspace_id}/permissions")
def list_workspace_permissions(
    workspace_id: str,
    member: WorkspaceMember = Depends(require_permission("workspace.view")),
):
    """List permissions assigned to each workspace role."""
    return {
        role: sorted(list(perms))
        for role, perms in ROLE_PERMISSIONS_MAP.items()
    }


@router.get("/{workspace_id}/members/{member_id}/permissions")
def get_member_permissions(
    workspace_id: str,
    member_id: str,
    member: WorkspaceMember = Depends(require_permission("workspace.view")),
    db: Session = Depends(get_db),
):
    """Get active permissions for a specific member."""
    target_member = (
        db.query(WorkspaceMember)
        .filter(WorkspaceMember.id == member_id, WorkspaceMember.workspace_id == workspace_id)
        .first()
    )
    if not target_member:
        raise NotFoundException("WorkspaceMember", member_id)

    perms = sorted(list(get_permissions_for_role(target_member.role)))
    return {
        "member_id": target_member.id,
        "user_id": target_member.user_id,
        "role": target_member.role,
        "permissions": perms,
    }
