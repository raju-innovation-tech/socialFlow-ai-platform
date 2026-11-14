from typing import Any, Dict, List, Optional
from sqlalchemy.orm import Session
from app.core.exceptions import NotFoundException
from app.models.post import Post, PostMedia, PostTarget, PostVariant
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
    ) -> List[Post]:
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
        payload = data.model_dump(exclude_unset=True)

        # Handle updating targets if explicitly provided
        if "target_account_ids" in payload:
            target_ids = payload.pop("target_account_ids")
            if target_ids is not None:
                self.db.query(PostTarget).filter(PostTarget.post_id == post.id).delete()
                for acc_id in target_ids:
                    self.repo.add_target(post.id, acc_id)

        # Handle updating variants if explicitly provided
        if "variants" in payload:
            new_variants = payload.pop("variants")
            if new_variants is not None:
                self.db.query(PostVariant).filter(PostVariant.post_id == post.id).delete()
                for v in new_variants:
                    self.repo.add_variant(post.id, v["platform"], v["customized_content"])

        # Handle updating media assets if explicitly provided
        if "media_asset_ids" in payload:
            media_ids = payload.pop("media_asset_ids")
            if media_ids is not None:
                self.db.query(PostMedia).filter(PostMedia.post_id == post.id).delete()
                for idx, m_id in enumerate(media_ids):
                    link = PostMedia(post_id=post.id, media_asset_id=m_id, display_order=idx)
                    self.db.add(link)

        return self.repo.update(post, payload)

    def delete_post(self, post_id: str) -> bool:
        post = self.get_post(post_id)
        return self.repo.delete(post)

    def duplicate_post(self, post_id: str, workspace_id: str) -> Post:
        """Duplicate an existing post into a fresh draft copy."""
        original = self.get_post(post_id)
        new_title = f"{original.title} (Copy)" if original.title else "Untitled Post (Copy)"

        new_post = Post(
            workspace_id=workspace_id,
            category_id=original.category_id,
            title=new_title,
            content=original.content,
            content_type=original.content_type,
            status="draft",
            scheduled_at=None,
        )
        self.db.add(new_post)
        self.db.flush()

        # Copy target social accounts
        for t in original.targets:
            self.repo.add_target(new_post.id, t.social_account_id)

        # Copy platform variants
        for v in original.variants:
            self.repo.add_variant(new_post.id, v.platform, v.customized_content)

        # Copy media associations
        for m in original.media_items:
            link = PostMedia(post_id=new_post.id, media_asset_id=m.media_asset_id, display_order=m.display_order)
            self.db.add(link)

        self.db.commit()
        self.db.refresh(new_post)
        return new_post
