# Webhooks & Real-time Event Ingestion

## 1. Overview
SocialFlow AI supports inbound webhook subscriptions for real-time delivery status receipts, message updates, and comment synchronization from Meta (Facebook, Instagram, WhatsApp) and Telegram.

## 2. Webhook Endpoints
- **WhatsApp Webhook Verification:** `GET /api/v1/integrations/whatsapp/webhook`
  - Validates `hub.mode=subscribe` and `hub.verify_token=settings.WHATSAPP_WEBHOOK_VERIFY_TOKEN`.
  - Responds with `hub.challenge` integer string on successful match.
- **WhatsApp Webhook Ingestion:** `POST /api/v1/integrations/whatsapp/webhook`
  - Asynchronously stores received payload into table `integration_events` with status `received`.

## 3. Database Ingestion Schema (`integration_events`)
- `id`: UUIDv4
- `workspace_id`: Target workspace if resolved
- `platform`: `whatsapp`, `facebook`, `instagram`, `telegram`
- `event_type`: e.g. `messages`, `delivery_receipt`, `mention`
- `payload_json`: Raw event payload preserved for processing
- `status`: `received` | `processed` | `failed` | `ignored`
- `processed_at`: Processing timestamp

