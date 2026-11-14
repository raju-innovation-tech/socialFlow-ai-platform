# LinkedIn Integration Guide

## 1. Official API Specification
- **API Versions:** Sign In with LinkedIn using OpenID Connect (v2) & Community Management API
- **Auth Protocol:** OAuth 2.0 (`response_type=code`)
- **Default Scopes:** `openid`, `profile`, `email`, `w_member_social`
- **Optional Scopes:** `w_organization_social`, `r_organization_social` (Requires approved Community Management product access)

## 2. Developer Console Configuration
1. Open [LinkedIn Developer Portal](https://www.linkedin.com/developers/).
2. Create an App and associate it with a verified LinkedIn Page.
3. In the **Products** tab, add:
   - **Sign In with LinkedIn using OpenID Connect** (Immediate access)
   - **Share on LinkedIn** (Immediate access for member personal publishing)
   - **Community Management API** (Submit access request for Company Page posting)
4. In the **Auth** tab:
   - Copy `Client ID` to `LINKEDIN_CLIENT_ID`.
   - Copy `Client Secret` to `LINKEDIN_CLIENT_SECRET`.
   - Add Authorized redirect URL: `http://localhost:8001/api/v1/integrations/linkedin/callback`.

## 3. Supported & Restricted Capabilities
- **Personal Feed Updates (`supported`):** Posts text, links, photos, multi-image posts, and PDF document carousels.
- **Company Page Updates (`requires_permission`):** Requires `w_organization_social`. If unapproved, the UI clearly displays "Requires LinkedIn Community Management API Approval".
- **Reels (`unavailable`):** LinkedIn does not support short-form Reels.

