from typing import Any, Dict, List
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.core.deps import get_current_super_admin
from app.core.rbac import PLATFORM_PERMISSIONS
from app.models.user import User
from app.models.workspace import Workspace

router = APIRouter(prefix="/admin", tags=["Platform Super Admin"])


@router.get("/users")
def admin_list_users(
    skip: int = 0,
    limit: int = 50,
    super_admin: User = Depends(get_current_super_admin),
    db: Session = Depends(get_db),
) -> List[Dict[str, Any]]:
    """Platform Super Admin: List all global platform users."""
    users = db.query(User).offset(skip).limit(limit).all()
    return [
        {
            "id": u.id,
            "email": u.email,
            "full_name": u.full_name,
            "is_active": u.is_active,
            "email_verified": u.email_verified,
            "account_status": u.account_status,
            "is_super_admin": u.is_super_admin,
            "created_at": u.created_at.isoformat(),
        }
        for u in users
    ]


@router.get("/workspaces")
def admin_list_workspaces(
    skip: int = 0,
    limit: int = 50,
    super_admin: User = Depends(get_current_super_admin),
    db: Session = Depends(get_db),
) -> List[Dict[str, Any]]:
    """Platform Super Admin: List all tenant workspaces across the system."""
    workspaces = db.query(Workspace).offset(skip).limit(limit).all()
    return [
        {
            "id": ws.id,
            "name": ws.name,
            "slug": ws.slug,
            "owner_id": ws.owner_id,
            "status": ws.status,
            "is_active": ws.is_active,
            "members_count": len(ws.members),
            "created_at": ws.created_at.isoformat(),
        }
        for ws in workspaces
    ]


@router.get("/roles")
def admin_list_platform_roles(
    super_admin: User = Depends(get_current_super_admin),
) -> Dict[str, Any]:
    """Platform Super Admin: View platform-level developer role configuration."""
    return {
        "platform_role": "SUPER_ADMIN",
        "description": "Full platform developer/operator authority across all workspaces.",
        "permissions": PLATFORM_PERMISSIONS,
    }

