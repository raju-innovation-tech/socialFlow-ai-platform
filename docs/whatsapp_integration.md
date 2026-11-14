# WhatsApp Business Platform Integration Guide

## 1. Official API Specification
- **API Product:** Meta WhatsApp Business Platform (Cloud API)
- **API Version:** Graph API `v20.0`
- **Supported Entities:** Verified WhatsApp Business Account (WABA), registered Phone Number ID, pre-approved Message Templates.

## 2. Meta Business Suite Configuration
1. Open [Meta Business Suite](https://business.facebook.com/).
2. Navigate to **WhatsApp Accounts -> API Setup**.
3. Create a Permanent System User with `whatsapp_business_management` and `whatsapp_business_messaging` permissions.
4. Copy:
   - **Phone Number ID**
   - **WhatsApp Business Account (WABA) ID**
   - **System User Access Token**
5. In **Webhooks**:
   - Callback URL: `https://your-domain.com/api/v1/integrations/whatsapp/webhook`
   - Verify Token: Matches `WHATSAPP_WEBHOOK_VERIFY_TOKEN` in `.env`.
   - Subscribe to `messages`.

## 3. Critical Reality: Channels, Groups & Communities Restrictions
- **WhatsApp Channels (`unavailable`):** Meta WhatsApp Cloud API does NOT support third-party SaaS automated broadcasting to WhatsApp Channels.
- **WhatsApp Groups (`unavailable`):** Automated group messaging is prohibited by Meta policies. Tools claiming automated group posting use web scraping / headless Chromium which violate WhatsApp Terms of Service and lead to permanent account bans.
- **WhatsApp Communities (`manual_only`):** Community announcements must be posted manually inside the WhatsApp client by Community Admins.

