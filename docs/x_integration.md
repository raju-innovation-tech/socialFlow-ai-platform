# X (Formerly Twitter) Integration Guide

## 1. Official API Specification
- **API Version:** Official X API v2
- **Auth Protocol:** OAuth 2.0 with PKCE (`code_challenge_method=S256`)
- **Required Scopes:** `tweet.read`, `tweet.write`, `users.read`, `offline.access`

## 2. X Developer Portal Configuration
1. Open [X Developer Portal](https://developer.x.com/).
2. Create a Project and App.
3. In **User authentication settings**:
   - App permissions: **Read and write**.
   - Type of App: **Web App, Automated App or Bot**.
   - Callback / Redirect URI: `http://localhost:8001/api/v1/integrations/x/callback`.
   - Copy `Client ID` to `X_CLIENT_ID`.
   - Copy `Client Secret` to `X_CLIENT_SECRET`.

## 3. Subscription Tier Realities
- **Free Tier:** Strictly limited to 1,500 tweet writes per month across the application. Read endpoints (analytics, mentions, user timeline) return `403 Forbidden` on the Free tier.
- **Basic Tier ($100/month):** Enables 10,000 read requests per month, 50,000 tweet writes per month, and public metrics access.
- **Pro Tier ($5,000/month):** For high-volume enterprise social listening and full historical search.

