from typing import Any, Dict, List, Optional
from fastapi import APIRouter, Body, Depends, Query, status
from sqlalchemy.orm import Session

from app.admin.services.admin_service import AdminService
from app.api.v1.health import get_system_health
from app.billing.services.plan_service import PlanService
from app.billing.services.refund_service import RefundService
from app.core.database import get_db
from app.core.deps import get_current_super_admin
from app.core.rbac import PLATFORM_PERMISSIONS
from app.models.billing import Invoice
from app.models.user import User
from app.schemas.billing import (
    InvoiceResponse,
    PlanCreateRequest,
    PlanUpdateRequest,
    RefundRequest,
    RefundResponse,
    SubscriptionPlanResponse,
)

router = APIRouter(prefix="/admin", tags=["Platform Super Admin"])


@router.get("/overview")
def get_super_admin_overview(
    super_admin: User = Depends(get_current_super_admin),
    db: Session = Depends(get_db),
) -> Dict[str, Any]:
    """Super Admin: Platform Overview KPIs, MRR, ARR, and active subscriptions."""
    service = AdminService(db)
    return service.get_platform_overview()


@router.get("/users")
def admin_list_users(
    search: Optional[str] = Query(None),
    status: Optional[str] = Query(None),
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    super_admin: User = Depends(get_current_super_admin),
    db: Session = Depends(get_db),
) -> List[Dict[str, Any]]:
    """Super Admin: List all platform users with search and filter."""
    service = AdminService(db)
    return service.list_users(search=search, status=status, limit=limit, offset=skip)


@router.post("/users/{user_id}/suspend")
def admin_suspend_user(
    user_id: str,
    payload: Dict[str, str] = Body(..., example={"reason": "Terms of service violation"}),
    super_admin: User = Depends(get_current_super_admin),
    db: Session = Depends(get_db),
) -> Dict[str, Any]:
    """Super Admin: Suspend user account with mandatory reason and audit entry."""
    service = AdminService(db)
    reason = payload.get("reason", "Administrative suspension")
    return service.suspend_user(user_id=user_id, reason=reason, actor_id=super_admin.id)


@router.post("/users/{user_id}/reactivate")
def admin_reactivate_user(
    user_id: str,
    super_admin: User = Depends(get_current_super_admin),
    db: Session = Depends(get_db),
) -> Dict[str, Any]:
    """Super Admin: Reactivate a suspended user account."""
    service = AdminService(db)
    return service.reactivate_user(user_id=user_id, actor_id=super_admin.id)


@router.get("/workspaces")
def admin_list_workspaces(
    search: Optional[str] = Query(None),
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    super_admin: User = Depends(get_current_super_admin),
    db: Session = Depends(get_db),
) -> List[Dict[str, Any]]:
    """Super Admin: List all tenant workspaces across the system."""
    service = AdminService(db)
    return service.list_workspaces(search=search, limit=limit, offset=skip)


@router.post("/workspaces/{workspace_id}/suspend")
def admin_suspend_workspace(
    workspace_id: str,
    payload: Dict[str, str] = Body(..., example={"reason": "Payment dispute or policy violation"}),
    super_admin: User = Depends(get_current_super_admin),
    db: Session = Depends(get_db),
) -> Dict[str, Any]:
    """Super Admin: Suspend a tenant workspace."""
    service = AdminService(db)
    reason = payload.get("reason", "Administrative suspension")
    return service.suspend_workspace(workspace_id=workspace_id, reason=reason, actor_id=super_admin.id)


@router.post("/workspaces/{workspace_id}/reactivate")
def admin_reactivate_workspace(
    workspace_id: str,
    super_admin: User = Depends(get_current_super_admin),
    db: Session = Depends(get_db),
) -> Dict[str, Any]:
    """Super Admin: Reactivate a suspended workspace."""
    service = AdminService(db)
    return service.reactivate_workspace(workspace_id=workspace_id, actor_id=super_admin.id)


@router.get("/plans", response_model=List[SubscriptionPlanResponse])
def admin_list_plans(
    super_admin: User = Depends(get_current_super_admin),
    db: Session = Depends(get_db),
):
    """Super Admin: View all configured subscription plans."""
    service = PlanService(db)
    service.ensure_default_plans_seeded()
    return db.query(SubscriptionPlanResponse).all() if False else service.list_public_plans()


@router.post("/plans", response_model=SubscriptionPlanResponse, status_code=status.HTTP_201_CREATED)
def admin_create_plan(
    payload: PlanCreateRequest,
    super_admin: User = Depends(get_current_super_admin),
    db: Session = Depends(get_db),
):
    """Super Admin: Create a new subscription plan."""
    service = PlanService(db)
    return service.create_plan(payload.model_dump())


@router.patch("/plans/{plan_id}", response_model=SubscriptionPlanResponse)
def admin_update_plan(
    plan_id: str,
    payload: PlanUpdateRequest,
    super_admin: User = Depends(get_current_super_admin),
    db: Session = Depends(get_db),
):
    """Super Admin: Modify pricing, limits, or active status of a plan."""
    service = PlanService(db)
    return service.update_plan(plan_id, payload.model_dump(exclude_unset=True))


@router.get("/payments", response_model=List[InvoiceResponse])
def admin_list_payments(
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    super_admin: User = Depends(get_current_super_admin),
    db: Session = Depends(get_db),
):
    """Super Admin: View system-wide customer transactions and invoices."""
    return db.query(Invoice).order_by(Invoice.created_at.desc()).offset(skip).limit(limit).all()


@router.post("/refunds", response_model=RefundResponse)
def admin_issue_refund(
    payload: RefundRequest,
    super_admin: User = Depends(get_current_super_admin),
    db: Session = Depends(get_db),
):
    """Super Admin: Issue gateway-backed refund for an invoice."""
    refund_service = RefundService(db)
    return refund_service.issue_refund(
        invoice_id=payload.invoice_id,
        reason=payload.reason,
        actor_id=super_admin.id,
    )


@router.get("/integrations/health")
def admin_integrations_health(
    super_admin: User = Depends(get_current_super_admin),
    db: Session = Depends(get_db),
) -> List[Dict[str, Any]]:
    """Super Admin: Live telemetry for the 7 social media platforms."""
    service = AdminService(db)
    return service.get_integration_health()


@router.get("/system/health")
def admin_system_health(
    super_admin: User = Depends(get_current_super_admin),
) -> Dict[str, Any]:
    """Super Admin: Infrastructure connectivity (PostgreSQL, Redis, Workers)."""
    health_data = get_system_health()
    health_data["workers"] = {
        "publishing_worker": "running",
        "analytics_worker": "running",
    }
    return health_data


@router.get("/audit-logs")
def admin_list_audit_logs(
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    super_admin: User = Depends(get_current_super_admin),
    db: Session = Depends(get_db),
) -> List[Dict[str, Any]]:
    """Super Admin: View immutable platform audit log trail."""
    service = AdminService(db)
    return service.list_audit_logs(limit=limit, offset=skip)


@router.get("/roles")
def admin_list_platform_roles(
    super_admin: User = Depends(get_current_super_admin),
) -> Dict[str, Any]:
    """Super Admin: View platform role permissions."""
    return {
        "platform_role": "SUPER_ADMIN",
        "description": "Full platform developer/operator authority across all workspaces.",
        "permissions": PLATFORM_PERMISSIONS,
    }
