from typing import List
from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.schemas.workspace import WorkspaceCreate, WorkspaceResponse, WorkspaceUpdate
from app.services.workspace_service import WorkspaceService

router = APIRouter(prefix="/workspaces", tags=["Workspaces"])


@router.get("", response_model=List[WorkspaceResponse])
def list_workspaces(skip: int = 0, limit: int = 50, db: Session = Depends(get_db)):
    """List workspaces (Development foundation - unprotected)."""
    service = WorkspaceService(db)
    return service.list_workspaces(skip=skip, limit=limit)


@router.post("", response_model=WorkspaceResponse, status_code=status.HTTP_201_CREATED)
def create_workspace(payload: WorkspaceCreate, db: Session = Depends(get_db)):
    """Create a new workspace."""
    service = WorkspaceService(db)
    return service.create_workspace(payload)


@router.get("/{workspace_id}", response_model=WorkspaceResponse)
def get_workspace(workspace_id: str, db: Session = Depends(get_db)):
    """Get single workspace details by ID."""
    service = WorkspaceService(db)
    return service.get_workspace(workspace_id)


@router.put("/{workspace_id}", response_model=WorkspaceResponse)
def update_workspace(workspace_id: str, payload: WorkspaceUpdate, db: Session = Depends(get_db)):
    """Update workspace details."""
    service = WorkspaceService(db)
    return service.update_workspace(workspace_id, payload)

