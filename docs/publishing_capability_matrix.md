# SocialFlow AI – Publishing Capability Matrix

This matrix specifies the publishing rules, constraints, and official API behaviors across all seven supported social platforms.

---

## 1. Platform Publishing Matrix

| Feature / Limit | LinkedIn | Facebook Pages | Instagram Pro | YouTube | X (Twitter) | WhatsApp Business | Telegram |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Primary API** | REST / Community API v2 | Meta Graph API v20.0 | Instagram Graph API v20.0 | YouTube Data API v3 | X API v2 + v1.1 Media | Meta Cloud API v20.0 | Telegram Bot API v7.x |
| **Authentication** | OAuth 2.0 Bearer | Page Access Token | User Access Token (Page link) | Google OAuth 2.0 | OAuth 2.0 PKCE | System User Access Token | BotFather Token |
| **Max Text Length** | 3,000 chars | 63,206 chars | 2,200 chars | Title: 100, Desc: 5,000 | 280 chars | 4,096 chars (Body: 1,024) | 4,096 (1,024 on media) |
| **Max Images** | Up to 9 images | Up to 10 photos | Up to 10 (Carousel) | None (Thumbnails only) | Up to 4 images | 1 image per message | Up to 10 in MediaGroup |
| **Supported Image Formats** | JPEG, PNG, GIF | JPEG, PNG, BMP, GIF | JPEG, PNG | JPEG, PNG (Thumbnail) | JPEG, PNG, GIF, WEBP | JPEG, PNG | JPEG, PNG, WEBP |
| **Max Image Size** | 10 MB | 10 MB | 8 MB | 2 MB (Thumbnail) | 5 MB | 5 MB | 10 MB |
| **Video Support** | MP4, max 200 MB, 10 min | MP4, MOV, max 4 GB, 240 min | MP4, MOV, max 100 MB, 15 min | MP4, MOV, AVI, max 128 GB, 12 hr | MP4, MOV, max 512 MB, 140 sec | MP4, 3GP, max 16 MB | MP4, max 50 MB (Bot API) |
| **Video Aspect Ratio** | 1:1, 4:5, 16:9 | 16:9, 1:1, 9:16 | 4:5 to 1.91:1 (Reels: 9:16) | 16:9 (Shorts: 9:16) | 16:9, 1:1, 9:16 | Any standard | Any standard |
| **Native API Scheduling** | No (Client-side / SaaS) | Supported via `scheduled_publish_time` | Supported via `scheduled_publish_time` | Supported via `status.publishAt` | No (Client-side / SaaS) | No (Client-side / SaaS) | No (Client-side / SaaS) |
| **Idempotency Support** | No (Client lock required) | No (Client lock required) | No (Client lock required) | No (Client lock required) | No (Client lock required) | Message idempotency via wamid | No (Client lock required) |
| **Channels / Groups** | Organization Pages supported | Facebook Pages only | Business/Creator only | Channels only | Profiles only | **Channels/Groups: UNAVAILABLE** | Channels & Groups supported |

---

## 2. Platform Deep Dives & Workflow Requirements

### A. LinkedIn
- **Publishing Endpoint:** `POST https://api.linkedin.com/v2/ugcPosts` or `POST https://api.linkedin.com/rest/posts`
- **Headers:** `LinkedIn-Version: 202401`, `X-Restli-Protocol-Version: 2.0.0`, `Authorization: Bearer <token>`
- **Workflow for Media:**
  1. Register upload: `POST /v2/assets?action=registerUpload` -> returns upload URL & asset URN.
  2. Stream upload binary bytes to the registered URL.
  3. Submit `ugcPosts` payload referencing the asset URN.
- **Reference:** [LinkedIn Consumer & Community Management API Documentation](https://learn.microsoft.com/en-us/linkedin/consumer/integrations/self-serve/share-on-linkedin)

### B. Facebook Pages
- **Publishing Endpoints:**
  * Text only: `POST https://graph.facebook.com/v20.0/{page_id}/feed` (`message`)
  * Single Photo: `POST https://graph.facebook.com/v20.0/{page_id}/photos` (`url` or multipart `source`, `caption`)
  * Video: `POST https://graph.facebook.com/v20.0/{page_id}/videos` (`description`, `file_url`)
- **Tokens:** Must use the Page Access Token acquired via `/me/accounts` (not the user token).
- **Reference:** [Meta Graph API Pages Documentation](https://developers.facebook.com/docs/pages-api/posts)

### C. Instagram Professional
- **Publishing Workflow (2-Step Asynchronous Container):**
  1. Create Container: `POST https://graph.facebook.com/v20.0/{ig_user_id}/media`
     - Parameters: `image_url` or `video_url`, `caption`, `media_type` (IMAGE, REELS, CAROUSEL, VIDEO).
     - Returns `{ "id": "<creation_id>" }`.
  2. Wait/Poll Status (for Video/Reels): `GET https://graph.facebook.com/v20.0/{creation_id}?fields=status_code`. Wait until `FINISHED`.
  3. Publish Container: `POST https://graph.facebook.com/v20.0/{ig_user_id}/media_publish`
     - Parameter: `creation_id`.
     - Returns `{ "id": "<media_id>" }`.
- **Reference:** [Instagram Graph API Content Publishing](https://developers.facebook.com/docs/instagram-api/guides/content-publishing)

### D. YouTube
- **Publishing Workflow:**
  1. Initiate Resumable Session: `POST https://www.googleapis.com/upload/youtube/v3/videos?uploadType=resumable&part=snippet,status`
  2. Upload Chunked Binary Stream.
  3. Receive Video Resource with YouTube ID (`https://youtube.com/watch?v={id}`).
- **Scheduling:** When scheduling, set `status.privacyStatus = "private"` and `status.publishAt = "<ISO_UTC_TIMESTAMP>"`.
- **Reference:** [YouTube Data API v3 Videos Insert](https://developers.google.com/youtube/v3/docs/videos/insert)

### E. X (Twitter)
- **Publishing Workflow:**
  1. If media attached: Upload binary chunks via `POST https://upload.twitter.com/1.1/media/upload.json` (`INIT` -> `APPEND` -> `FINALIZE`).
  2. Receive `media_id_string`.
  3. Create Tweet: `POST https://api.twitter.com/2/tweets` with `{ "text": "...", "media": { "media_ids": ["..."] } }`.
- **Reference:** [X API v2 Manage Tweets](https://developer.x.com/en/docs/twitter-api/tweets/manage-tweets/api-reference/post-tweets)

### F. WhatsApp Business Platform
- **Publishing Endpoint:** `POST https://graph.facebook.com/v20.0/{phone_number_id}/messages`
- **Rules:**
  * Free-form text and media messages only allowed within the 24-hour customer service window.
  * Outside the 24-hour window, only pre-approved Meta message templates may be sent.
  * Channels & Groups: Mark as `UNAVAILABLE` or `MANUAL_ONLY`.
- **Reference:** [WhatsApp Business Cloud API Messages Documentation](https://developers.facebook.com/docs/whatsapp/cloud-api/guides/send-messages)

### G. Telegram
- **Publishing Endpoints:**
  * Text: `POST https://api.telegram.org/bot{token}/sendMessage` (`chat_id`, `text`, `parse_mode="HTML"`)
  * Photo: `POST https://api.telegram.org/bot{token}/sendPhoto` (`chat_id`, `photo`, `caption`)
  * Video: `POST https://api.telegram.org/bot{token}/sendVideo` (`chat_id`, `video`, `caption`)
- **Reference:** [Telegram Bot API Documentation](https://core.telegram.org/bots/api)

