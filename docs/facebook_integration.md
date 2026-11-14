# Facebook Pages Integration Guide

## 1. Official API Specification
- **API Version:** Meta Graph API v20.0
- **Auth Protocol:** Facebook Login / OAuth 2.0 (`dialog/oauth`)
- **Required Scopes:** `public_profile`, `email`, `pages_show_list`, `pages_read_engagement`, `pages_manage_posts`
- **Token Exchange:** Short-lived user access token is exchanged for a long-lived 60-day user token via `grant_type=fb_exchange_token`. Page access tokens acquired from `/me/accounts` do not expire as long as user permissions remain valid.

## 2. Developer Console Configuration
1. Open [Meta for Developers](https://developers.facebook.com/).
2. Create an App of type **Business**.
3. Under **Add Use Cases**, select **Manage Pages and Publish Content**.
4. In **App Settings -> Basic**:
   - Copy `App ID` to `META_APP_ID`.
   - Copy `App Secret` to `META_APP_SECRET`.
5. Under **Facebook Login for Business -> Settings**:
   - Add Valid OAuth Redirect URI: `http://localhost:8001/api/v1/integrations/facebook/callback`.

## 3. Important Realities & Constraints
- **Personal Profiles (`unavailable`):** Automated publishing to personal Facebook user timelines is strictly prohibited by Meta platform policies. SocialFlow AI only supports Facebook Pages where the user holds management tasks.
- **Page Discovery:** When authorized, SocialFlow AI fetches all accessible Pages from `/me/accounts` and allows the user to select specific Pages to connect to the active workspace.

