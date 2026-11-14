from typing import List, Optional
from sqlalchemy.orm import Session
from app.models.post import Post, PostVariant, PostTarget, PostMedia
from app.repositories.base import BaseRepository


class PostRepository(BaseRepository[Post]):
    def __init__(self, db: Session):
        super().__init__(Post, db)

    def list_by_workspace(
        self,
        workspace_id: str,
        status: Optional[str] = None,
        skip: int = 0,
        limit: int = 50,
    ) -> List[Post]:
        query = self.db.query(Post).filter(Post.workspace_id == workspace_id)
        if status:
            query = query.filter(Post.status == status)
        return query.order_by(Post.created_at.desc()).offset(skip).limit(limit).all()

    def add_target(self, post_id: str, social_account_id: str) -> PostTarget:
        target = PostTarget(post_id=post_id, social_account_id=social_account_id)
        self.db.add(target)
        self.db.commit()
        return target

    def add_variant(self, post_id: str, platform: str, customized_content: str) -> PostVariant:
        variant = PostVariant(post_id=post_id, platform=platform, customized_content=customized_content)
        self.db.add(variant)
        self.db.commit()
        return variant

