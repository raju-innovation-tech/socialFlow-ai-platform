import hashlib
import os
import shutil
import uuid
from typing import Tuple
from fastapi import UploadFile
from app.core.config import settings
from app.core.exceptions import BadRequestException


class LocalStorageService:
    def __init__(self, base_dir: str = settings.LOCAL_MEDIA_DIR):
        self.base_dir = os.path.abspath(base_dir)
        os.makedirs(self.base_dir, exist_ok=True)

    def save_upload(self, file: UploadFile) -> Tuple[str, int, str]:
        # Validate MIME
        if file.content_type not in settings.ALLOWED_MIME_TYPES:
            raise BadRequestException(
                f"File MIME type '{file.content_type}' is not supported. Allowed: {settings.ALLOWED_MIME_TYPES}",
                error_code="INVALID_FILE_TYPE",
            )

        # Generate unique storage filename to prevent collisions and path traversal
        ext = os.path.splitext(file.filename or "")[1].lower()
        if not ext:
            ext = ".bin"
        safe_filename = f"{uuid.uuid4().hex}{ext}"
        destination_path = os.path.join(self.base_dir, safe_filename)

        # Stream save and calculate hash & size
        hasher = hashlib.sha256()
        total_size = 0
        max_bytes = settings.MAX_UPLOAD_SIZE_MB * 1024 * 1024

        try:
            with open(destination_path, "wb") as buffer:
                while chunk := file.file.read(1024 * 64):
                    total_size += len(chunk)
                    if total_size > max_bytes:
                        raise BadRequestException(
                            f"File size exceeds maximum limit of {settings.MAX_UPLOAD_SIZE_MB}MB",
                            error_code="FILE_TOO_LARGE",
                        )
                    hasher.update(chunk)
                    buffer.write(chunk)
        except Exception:
            if os.path.exists(destination_path):
                os.remove(destination_path)
            raise

        file_hash = hasher.hexdigest()
        return destination_path, total_size, file_hash

    def delete_file(self, file_path: str) -> bool:
        if os.path.exists(file_path):
            try:
                os.remove(file_path)
                return True
            except OSError:
                return False
        return False


storage_service = LocalStorageService()

