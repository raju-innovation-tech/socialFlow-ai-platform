from typing import Any, Dict, List, Optional
from app.models.media import MediaAsset
from app.publishing.adapters.adapter_registry import publishing_registry


class ContentValidationService:
    """Multi-platform content validation engine enforcing official platform constraints."""

    @staticmethod
    def validate_for_platforms(
        base_content: str,
        platforms: List[str],
        media_items: Optional[List[MediaAsset]] = None,
        platform_variants: Optional[Dict[str, str]] = None,
        extra_params: Optional[Dict[str, Any]] = None,
    ) -> Dict[str, Dict[str, Any]]:
        """Validate content across all selected platforms independently.
        Returns a dictionary mapping platform name to validation status and list of errors/warnings.
        """
        results = {}
        variants = platform_variants or {}

        for platform in platforms:
            adapter = publishing_registry.get(platform)
            if not adapter:
                results[platform] = {
                    "is_valid": False,
                    "errors": [f"Platform '{platform}' is not supported."],
                    "character_count": len(variants.get(platform, base_content)),
                }
                continue

            content_to_check = variants.get(platform, base_content)
            errors = adapter.validate_content(
                text=content_to_check,
                media_items=media_items,
                extra_params=extra_params,
            )

            results[platform] = {
                "is_valid": len(errors) == 0,
                "errors": errors,
                "character_count": len(content_to_check),
                "media_count": len(media_items) if media_items else 0,
            }

        return results

