from sqlalchemy import Column, DateTime, ForeignKey, Integer, String, Text
from sqlalchemy.orm import relationship
from app.core.database import Base
from app.models.base import TimestampMixin, UUIDMixin


class PublishingJob(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "publishing_jobs"

    post_id = Column(String(36), ForeignKey("posts.id", ondelete="CASCADE"), nullable=False, index=True)
    scheduled_time = Column(DateTime(timezone=True), nullable=False, index=True)
    status = Column(String(32), default="pending", nullable=False)  # pending, in_progress, completed, failed, cancelled
    retry_count = Column(Integer, default=0, nullable=False)
    max_retries = Column(Integer, default=3, nullable=False)
    last_error = Column(Text, nullable=True)
    idempotency_key = Column(String(128), unique=True, index=True, nullable=False)

    # Relationships
    post = relationship("Post", back_populates="publishing_jobs")
    attempts = relationship("PublishingAttempt", back_populates="job", cascade="all, delete-orphan")


class PublishingAttempt(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "publishing_attempts"

    job_id = Column(String(36), ForeignKey("publishing_jobs.id", ondelete="CASCADE"), nullable=False, index=True)
    attempt_number = Column(Integer, nullable=False)
    attempted_at = Column(DateTime(timezone=True), nullable=False)
    duration_ms = Column(Integer, nullable=True)
    status = Column(String(32), nullable=False)  # success, failure
    response_payload = Column(Text, nullable=True)
    error_details = Column(Text, nullable=True)

    # Relationships
    job = relationship("PublishingJob", back_populates="attempts")


class PublishingOutbox(Base, UUIDMixin, TimestampMixin):
    __tablename__ = "publishing_outbox"

    event_type = Column(String(64), nullable=False, index=True)  # post.schedule, post.publish, post.retry
    aggregate_id = Column(String(36), nullable=False, index=True)
    payload = Column(Text, nullable=False)
    status = Column(String(32), default="pending", nullable=False)  # pending, processed, failed
    processed_at = Column(DateTime(timezone=True), nullable=True)

