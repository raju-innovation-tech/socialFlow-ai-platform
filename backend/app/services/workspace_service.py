from slugify import slugify
from sqlalchemy.orm import Session
from app.core.exceptions import ConflictException, NotFoundException
from app.models.workspace import Workspace
from app.repositories.workspace_repo import WorkspaceRepository
from app.schemas.workspace import WorkspaceCreate, WorkspaceUpdate


class WorkspaceService:
    def __init__(self, db: Session):
        self.repo = WorkspaceRepository(db)

    def get_workspace(self, workspace_id: str) -> Workspace:
        ws = self.repo.get_by_id(workspace_id)
        if not ws:
            raise NotFoundException("Workspace", workspace_id)
        return ws

    def list_workspaces(self, skip: int = 0, limit: int = 50):
        return self.repo.list_active(skip=skip, limit=limit)

    def create_workspace(self, data: WorkspaceCreate) -> Workspace:
        slug = data.slug or slugify(data.name)
        if self.repo.get_by_slug(slug):
            raise ConflictException(f"Workspace with slug '{slug}' already exists.")

        workspace = Workspace(
            name=data.name,
            slug=slug,
            description=data.description,
            logo_url=data.logo_url,
        )
        return self.repo.create(workspace)

    def update_workspace(self, workspace_id: str, data: WorkspaceUpdate) -> Workspace:
        ws = self.get_workspace(workspace_id)
        return self.repo.update(ws, data.model_dump(exclude_unset=True))

