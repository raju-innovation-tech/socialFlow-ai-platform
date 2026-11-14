# Instagram Professional Integration Guide

## 1. Official API Specification
- **API Version:** Instagram Graph API (via Meta Graph API v20.0)
- **Auth Protocol:** Facebook Login / OAuth 2.0 with linked Facebook Page discovery
- **Required Scopes:** `instagram_basic`, `instagram_content_publish`, `instagram_manage_insights`, `pages_show_list`, `pages_read_engagement`

## 2. Mandatory Account Eligibility
1. The Instagram account **must be a Professional Account (Business or Creator)**. Personal Instagram accounts are strictly unsupported by Meta Graph API.
2. The Instagram Professional account **must be linked to a Facebook Page** that the user manages.

## 3. Supported Capabilities
- **Single Photo:** Container API creation followed by `POST /{ig-user-id}/media_publish`.
- **Carousel Posts:** Up to 10 images or videos bundled in a carousel container.
- **Instagram Reels:** Supported with `media_type=REELS` and vertical 9:16 aspect ratio.
- **Account & Media Insights:** Impressions, reach, profile views, follower count.
- **Stories (`restricted`):** Requires explicit Meta App Review approval for Stories publishing.

