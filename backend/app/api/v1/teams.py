from typing import Any, Dict, List
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.models.membership import WorkspaceMember

router = APIRouter(prefix="/teams", tags=["Teams"])


@router.get("/members")
def list_workspace_members(
    workspace_id: str = Query(..., description="Workspace ID"),
    db: Session = Depends(get_db),
) -> List[Dict[str, Any]]:
    """List members and assigned roles in a workspace."""
    members = db.query(WorkspaceMember).filter(WorkspaceMember.workspace_id == workspace_id).all()
    results = []
    for m in members:
        results.append({
            "id": m.id,
            "workspace_id": m.workspace_id,
            "user_id": m.user_id,
            "role": m.role,
            "status": m.status,
            "created_at": m.created_at.isoformat() if m.created_at else None,
        })
    return results


@router.get("/roles")
def list_available_roles() -> List[Dict[str, str]]:
    """List system roles available for assignment."""
    return [
        {"role": "owner", "description": "Full access to workspace, billing and platform settings"},
        {"role": "admin", "description": "Manage members, accounts, settings and content"},
        {"role": "editor", "description": "Create, edit and schedule posts and media"},
        {"role": "approver", "description": "Review, approve and reject queued content"},
        {"role": "analyst", "description": "Access performance metrics and generate reports"},
        {"role": "viewer", "description": "Read-only access to calendar, posts and analytics"},
    ]

