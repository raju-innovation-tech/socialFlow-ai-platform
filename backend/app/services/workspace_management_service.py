import uuid
from datetime import datetime, timedelta, timezone
from typing import Any, Dict, List, Optional
from sqlalchemy.orm import Session
from app.core.exceptions import BadRequestException, ConflictException, ForbiddenException, NotFoundException
from app.core.logging import logger
from app.core.rbac import get_permissions_for_role
from app.core.security import generate_secure_token, hash_token
from app.models.audit_log import AuditLog
from app.models.membership import WorkspaceInvitation, WorkspaceMember
from app.models.user import User
from app.models.workspace import Workspace
from app.schemas.auth import (
    InviteMemberRequest,
    SwitchWorkspaceResponse,
    WorkspaceMemberDetailResponse,
)


class WorkspaceManagementService:
    def __init__(self, db: Session):
        self.db = db

    def _log_audit(
        self,
        action: str,
        entity_type: str,
        entity_id: str,
        actor_id: Optional[str] = None,
        workspace_id: Optional[str] = None,
        metadata: Optional[str] = None,
    ):
        try:
            log = AuditLog(
                action=action,
                entity_type=entity_type,
                entity_id=entity_id,
                actor_id=actor_id,
                workspace_id=workspace_id,
                metadata_json=metadata,
            )
            self.db.add(log)
            self.db.commit()
        except Exception as e:
            logger.error("Failed to write audit log: %s", e)
            self.db.rollback()

    def list_user_workspaces(self, user: User) -> List[Dict[str, Any]]:
        if user.is_super_admin:
            workspaces = self.db.query(Workspace).filter(Workspace.is_active == True).all()
            return [
                {
                    "id": ws.id,
                    "name": ws.name,
                    "slug": ws.slug,
                    "role": "owner",
                    "is_owner": True,
                    "created_at": ws.created_at.isoformat(),
                }
                for ws in workspaces
            ]

        memberships = (
            self.db.query(WorkspaceMember)
            .join(Workspace, Workspace.id == WorkspaceMember.workspace_id)
            .filter(
                WorkspaceMember.user_id == user.id,
                WorkspaceMember.status == "active",
                Workspace.is_active == True,
            )
            .all()
        )

        return [
            {
                "id": m.workspace.id,
                "name": m.workspace.name,
                "slug": m.workspace.slug,
                "role": m.role,
                "is_owner": (m.role == "owner"),
                "created_at": m.workspace.created_at.isoformat(),
            }
            for m in memberships
        ]

    def switch_workspace(self, user: User, workspace_id: str) -> SwitchWorkspaceResponse:
        ws = self.db.query(Workspace).filter(Workspace.id == workspace_id, Workspace.is_active == True).first()
        if not ws:
            raise NotFoundException("Workspace", workspace_id)

        role = "owner" if user.is_super_admin else None
        if not user.is_super_admin:
            member = self.db.query(WorkspaceMember).filter(
                WorkspaceMember.workspace_id == workspace_id,
                WorkspaceMember.user_id == user.id,
                WorkspaceMember.status == "active",
            ).first()
            if not member:
                raise ForbiddenException(f"You do not have active membership in workspace '{workspace_id}'.")
            role = member.role

        permissions = sorted(list(get_permissions_for_role(role)))

        return SwitchWorkspaceResponse(
            workspace_id=ws.id,
            workspace_name=ws.name,
            workspace_slug=ws.slug,
            role=role,
            permissions=permissions,
        )

    def list_members(self, workspace_id: str) -> List[WorkspaceMemberDetailResponse]:
        members = (
            self.db.query(WorkspaceMember)
            .filter(WorkspaceMember.workspace_id == workspace_id)
            .all()
        )
        results = []
        for m in members:
            results.append(
                WorkspaceMemberDetailResponse(
                    id=m.id,
                    workspace_id=m.workspace_id,
                    user_id=m.user_id,
                    email=m.user.email,
                    full_name=m.user.full_name,
                    role=m.role,
                    status=m.status,
                    joined_at=m.joined_at,
                )
            )
        return results

    def invite_member(
        self,
        workspace_id: str,
        inviter: User,
        payload: InviteMemberRequest,
    ) -> WorkspaceInvitation:
        normalized_email = payload.email.strip().lower()

        # Check if already an active member
        existing_user = self.db.query(User).filter(User.normalized_email == normalized_email).first()
        if existing_user:
            active_member = self.db.query(WorkspaceMember).filter(
                WorkspaceMember.workspace_id == workspace_id,
                WorkspaceMember.user_id == existing_user.id,
                WorkspaceMember.status == "active",
            ).first()
            if active_member:
                raise ConflictException(f"User '{normalized_email}' is already an active member of this workspace.")

        now = datetime.now(timezone.utc)

        # Invalidate old pending invitations for this email in this workspace
        self.db.query(WorkspaceInvitation).filter(
            WorkspaceInvitation.workspace_id == workspace_id,
            WorkspaceInvitation.email == normalized_email,
            WorkspaceInvitation.status == "pending",
        ).update({"status": "revoked"})

        plain_token = generate_secure_token(32)
        invitation = WorkspaceInvitation(
            workspace_id=workspace_id,
            email=normalized_email,
            role=payload.role,
            invited_by_user_id=inviter.id,
            token=plain_token,
            token_hash=hash_token(plain_token),
            status="pending",
            expires_at=now + timedelta(days=7),
        )
        self.db.add(invitation)
        self.db.commit()
        self.db.refresh(invitation)

        self._log_audit(
            action="invitation_created",
            entity_type="workspace_invitation",
            entity_id=invitation.id,
            actor_id=inviter.id,
            workspace_id=workspace_id,
            metadata=f"Invited {normalized_email} with role {payload.role}",
        )

        return invitation

    def accept_invitation(self, user: User, token_plain: str) -> WorkspaceMember:
        token_hash = hash_token(token_plain.strip())
        now = datetime.now(timezone.utc)

        invitation = (
            self.db.query(WorkspaceInvitation)
            .filter(
                WorkspaceInvitation.token_hash == token_hash,
                WorkspaceInvitation.status == "pending",
                WorkspaceInvitation.expires_at > now,
            )
            .first()
        )

        if not invitation:
            raise BadRequestException("Invitation is invalid or has expired.")

        # Ensure invited email matches accepting user
        if invitation.email.lower() != user.normalized_email:
            raise ForbiddenException(
                f"This invitation was sent to '{invitation.email}', but you are signed in as '{user.email}'."
            )

        # Check existing membership
        member = self.db.query(WorkspaceMember).filter(
            WorkspaceMember.workspace_id == invitation.workspace_id,
            WorkspaceMember.user_id == user.id,
        ).first()

        if member:
            member.role = invitation.role
            member.status = "active"
        else:
            member = WorkspaceMember(
                workspace_id=invitation.workspace_id,
                user_id=user.id,
                role=invitation.role,
                status="active",
                joined_at=now,
            )
            self.db.add(member)

        invitation.status = "accepted"
        invitation.accepted_at = now
        self.db.commit()
        self.db.refresh(member)

        self._log_audit(
            action="invitation_accepted",
            entity_type="workspace_member",
            entity_id=member.id,
            actor_id=user.id,
            workspace_id=invitation.workspace_id,
        )

        return member

    def reject_invitation(self, user: User, token_plain: str) -> bool:
        token_hash = hash_token(token_plain.strip())
        invitation = self.db.query(WorkspaceInvitation).filter(
            WorkspaceInvitation.token_hash == token_hash,
            WorkspaceInvitation.status == "pending",
        ).first()

        if not invitation:
            raise BadRequestException("Invitation is invalid or has already been processed.")

        invitation.status = "rejected"
        self.db.commit()
        return True

    def cancel_invitation(self, workspace_id: str, invitation_id: str, admin: User):
        invitation = self.db.query(WorkspaceInvitation).filter(
            WorkspaceInvitation.id == invitation_id,
            WorkspaceInvitation.workspace_id == workspace_id,
        ).first()

        if not invitation:
            raise NotFoundException("Invitation", invitation_id)

        invitation.status = "revoked"
        self.db.commit()

        self._log_audit(
            action="invitation_cancelled",
            entity_type="workspace_invitation",
            entity_id=invitation_id,
            actor_id=admin.id,
            workspace_id=workspace_id,
        )

    def update_member_role(
        self,
        workspace_id: str,
        member_id: str,
        new_role: str,
        admin: User,
    ) -> WorkspaceMember:
        member = self.db.query(WorkspaceMember).filter(
            WorkspaceMember.id == member_id,
            WorkspaceMember.workspace_id == workspace_id,
        ).first()

        if not member:
            raise NotFoundException("WorkspaceMember", member_id)

        if member.user_id == admin.id and not admin.is_super_admin:
            raise ForbiddenException("You cannot modify your own workspace role.")

        if member.role == "owner" and not admin.is_super_admin:
            raise ForbiddenException("Workspace owner's role cannot be modified. Use transfer ownership instead.")

        old_role = member.role
        member.role = new_role
        self.db.commit()
        self.db.refresh(member)

        self._log_audit(
            action="member_role_updated",
            entity_type="workspace_member",
            entity_id=member.id,
            actor_id=admin.id,
            workspace_id=workspace_id,
            metadata=f"Role changed from {old_role} to {new_role}",
        )

        return member

    def remove_member(self, workspace_id: str, member_id: str, admin: User):
        member = self.db.query(WorkspaceMember).filter(
            WorkspaceMember.id == member_id,
            WorkspaceMember.workspace_id == workspace_id,
        ).first()

        if not member:
            raise NotFoundException("WorkspaceMember", member_id)

        if member.role == "owner":
            raise ForbiddenException("The workspace owner cannot be removed. Transfer ownership first.")

        if member.user_id == admin.id:
            raise ForbiddenException("You cannot remove yourself. Leave workspace or delete account.")

        self.db.delete(member)
        self.db.commit()

        self._log_audit(
            action="member_removed",
            entity_type="workspace_member",
            entity_id=member_id,
            actor_id=admin.id,
            workspace_id=workspace_id,
        )

    def transfer_ownership(
        self,
        workspace_id: str,
        new_owner_user_id: str,
        current_owner: User,
    ) -> Workspace:
        ws = self.db.query(Workspace).filter(Workspace.id == workspace_id).first()
        if not ws:
            raise NotFoundException("Workspace", workspace_id)

        if ws.owner_id != current_owner.id and not current_owner.is_super_admin:
            raise ForbiddenException("Only the current workspace owner can transfer ownership.")

        if ws.owner_id == new_owner_user_id:
            raise BadRequestException("User is already the owner of this workspace.")

        # Ensure new owner is an active member
        new_owner_member = self.db.query(WorkspaceMember).filter(
            WorkspaceMember.workspace_id == workspace_id,
            WorkspaceMember.user_id == new_owner_user_id,
            WorkspaceMember.status == "active",
        ).first()

        if not new_owner_member:
            raise BadRequestException("New owner must be an active member of this workspace.")

        # Update previous owner to Admin
        old_owner_member = self.db.query(WorkspaceMember).filter(
            WorkspaceMember.workspace_id == workspace_id,
            WorkspaceMember.user_id == ws.owner_id,
        ).first()

        if old_owner_member:
            old_owner_member.role = "admin"

        new_owner_member.role = "owner"
        ws.owner_id = new_owner_user_id
        self.db.commit()
        self.db.refresh(ws)

        self._log_audit(
            action="workspace_ownership_transferred",
            entity_type="workspace",
            entity_id=workspace_id,
            actor_id=current_owner.id,
            workspace_id=workspace_id,
            metadata=f"Ownership transferred to user {new_owner_user_id}",
        )

        return ws

