# YouTube Integration Guide

## 1. Official API Specification
- **API Version:** YouTube Data API v3
- **Auth Protocol:** Google OAuth 2.0 with offline access (`access_type=offline`, `prompt=consent`)
- **Required Scopes:**
  - `https://www.googleapis.com/auth/youtube.readonly`
  - `https://www.googleapis.com/auth/youtube.upload`
  - `https://www.googleapis.com/auth/userinfo.profile`

## 2. Google Cloud Console Configuration
1. Open [Google Cloud Console](https://console.cloud.google.com/).
2. Create or select a project and enable **YouTube Data API v3**.
3. In **APIs & Services -> Credentials**:
   - Create an OAuth 2.0 Client ID (Web Application).
   - Add Authorized redirect URI: `http://localhost:8001/api/v1/integrations/youtube/callback`.
   - Copy `Client ID` to `GOOGLE_CLIENT_ID`.
   - Copy `Client Secret` to `GOOGLE_CLIENT_SECRET`.

## 3. Quota & Multi-Channel Handling
- **Daily Quota:** Google allocates a default quota of 10,000 units per day. Reading channel data costs 1 unit; video upload costs 1,600 units (allowing ~6 uploads per day on default quota).
- **Multi-Channel Accounts:** If a Google account manages multiple Brand Channels, `/channels?mine=true` discovers all channels and prompts the user to select their desired channel.
- **Community Posts (`unavailable`):** YouTube Data API v3 does not offer endpoints to publish Community tab text or image polls.

