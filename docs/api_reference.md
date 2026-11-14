# SocialFlow AI – API Reference (v1)

Base URL: `http://localhost:8001/api/v1`  
Interactive Swagger UI: `http://localhost:8001/docs`  
ReDoc UI: `http://localhost:8001/redoc`  

---

## 1. Health Endpoints
- `GET /health`: Overall system health (App, PostgreSQL, Redis).
- `GET /api/v1/health`: V1 system health.
- `GET /api/v1/health/database`: PostgreSQL connection test.
- `GET /api/v1/health/redis`: Redis connection test.

---

## 2. Workspaces
- `GET /api/v1/workspaces`: List workspaces.
- `POST /api/v1/workspaces`: Create a new workspace.
- `GET /api/v1/workspaces/{workspace_id}`: Fetch single workspace.
- `PUT /api/v1/workspaces/{workspace_id}`: Update workspace details.

### Sample Request (POST /api/v1/workspaces):
```json
{
  "name": "Acme Marketing",
  "description": "Primary agency workspace",
  "logo_url": "https://example.com/logo.png"
}
```

---

## 3. Social Accounts
- `GET /api/v1/social-accounts?workspace_id={id}`: List accounts for workspace.
- `POST /api/v1/social-accounts`: Connect a platform account.
- `GET /api/v1/social-accounts/{account_id}`: Single account details.
- `DELETE /api/v1/social-accounts/{account_id}`: Disconnect account.

---

## 4. Posts & Content
- `GET /api/v1/posts?workspace_id={id}&status={status}`: List posts.
- `POST /api/v1/posts`: Create post with target platforms and variants.
- `GET /api/v1/posts/{post_id}`: Single post details.
- `PUT /api/v1/posts/{post_id}`: Update post content or status.
- `DELETE /api/v1/posts/{post_id}`: Delete post.

---

## 5. Media Library
- `GET /api/v1/media?workspace_id={id}`: List uploaded assets.
- `POST /api/v1/media/upload`: Multipart upload with MIME & size validation.
- `GET /api/v1/media/{media_id}`: Single media asset.
- `DELETE /api/v1/media/{media_id}`: Delete asset and remove from disk.

---

## 6. Campaigns
- `GET /api/v1/campaigns?workspace_id={id}`: List campaigns.
- `POST /api/v1/campaigns`: Create campaign and link posts.
- `GET /api/v1/campaigns/{campaign_id}`: Single campaign.
- `PUT /api/v1/campaigns/{campaign_id}`: Update campaign.

---

## 7. Analytics & Reports
- `GET /api/v1/analytics/overview?workspace_id={id}`: Aggregated KPIs and 7-day timeline.
- `GET /api/v1/analytics/platforms?workspace_id={id}`: Breakdown across all 7 networks.

---

## 8. Notifications
- `GET /api/v1/notifications?workspace_id={id}&unread_only=true`: In-app notification list.
- `GET /api/v1/notifications/{notification_id}`: Mark notification as read.

---

## 9. Billing
- `GET /api/v1/billing/plans`: SaaS pricing tiers (Free, Pro, Enterprise).
- `GET /api/v1/billing/subscription?workspace_id={id}`: Active workspace subscription.

---

## 10. Teams & Roles
- `GET /api/v1/teams/members?workspace_id={id}`: Team members in workspace.
- `GET /api/v1/teams/roles`: Available RBAC roles.

