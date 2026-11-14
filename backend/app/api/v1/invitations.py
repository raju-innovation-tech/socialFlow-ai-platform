from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.core.deps import get_current_active_user
from app.models.user import User
from app.schemas.auth import AcceptInvitationRequest
from app.services.workspace_management_service import WorkspaceManagementService

router = APIRouter(prefix="/invitations", tags=["Invitations"])


@router.post("/accept", status_code=status.HTTP_200_OK)
def accept_invitation(
    payload: AcceptInvitationRequest,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
):
    """Accept an email invitation to join a workspace."""
    service = WorkspaceManagementService(db)
    member = service.accept_invitation(current_user, payload.token)
    return {
        "message": "Invitation accepted successfully.",
        "workspace_id": member.workspace_id,
        "role": member.role,
    }


@router.post("/reject", status_code=status.HTTP_200_OK)
def reject_invitation(
    payload: AcceptInvitationRequest,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
):
    """Reject an invitation."""
    service = WorkspaceManagementService(db)
    service.reject_invitation(current_user, payload.token)
    return {"message": "Invitation rejected."}

