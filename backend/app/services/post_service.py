from typing import Optional
from sqlalchemy.orm import Session
from app.core.exceptions import NotFoundException
from app.models.post import Post, PostMedia
from app.repositories.post_repo import PostRepository
from app.schemas.post import PostCreate, PostUpdate


class PostService:
    def __init__(self, db: Session):
        self.db = db
        self.repo = PostRepository(db)

    def list_posts(
        self,
        workspace_id: str,
        status: Optional[str] = None,
        skip: int = 0,
        limit: int = 50,
    ):
        return self.repo.list_by_workspace(workspace_id, status=status, skip=skip, limit=limit)

    def get_post(self, post_id: str) -> Post:
        post = self.repo.get_by_id(post_id)
        if not post:
            raise NotFoundException("Post", post_id)
        return post

    def create_post(self, data: PostCreate) -> Post:
        status = "scheduled" if data.scheduled_at else "draft"
        post = Post(
            workspace_id=data.workspace_id,
            category_id=data.category_id,
            title=data.title,
            content=data.content,
            content_type=data.content_type,
            status=status,
            scheduled_at=data.scheduled_at,
        )
        self.repo.create(post)

        # Attach target social accounts
        if data.target_account_ids:
            for acc_id in data.target_account_ids:
                self.repo.add_target(post.id, acc_id)

        # Attach platform variants
        if data.variants:
            for v in data.variants:
                self.repo.add_variant(post.id, v.platform, v.customized_content)

        # Attach media assets
        if data.media_asset_ids:
            for idx, m_id in enumerate(data.media_asset_ids):
                link = PostMedia(post_id=post.id, media_asset_id=m_id, display_order=idx)
                self.db.add(link)
            self.db.commit()

        return post

    def update_post(self, post_id: str, data: PostUpdate) -> Post:
        post = self.get_post(post_id)
        return self.repo.update(post, data.model_dump(exclude_unset=True))

    def delete_post(self, post_id: str) -> bool:
        post = self.get_post(post_id)
        return self.repo.delete(post)

