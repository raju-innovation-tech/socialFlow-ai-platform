# Social Platform Integration Setup Guide

## 1. Quick Setup Reference

| Platform | Required Environment Variables | Setup Location |
| :--- | :--- | :--- |
| **LinkedIn** | `LINKEDIN_CLIENT_ID`, `LINKEDIN_CLIENT_SECRET`, `LINKEDIN_REDIRECT_URI` | [LinkedIn Developer Portal](https://www.linkedin.com/developers/) |
| **Facebook Pages** | `META_APP_ID`, `META_APP_SECRET`, `META_REDIRECT_URI` | [Meta for Developers](https://developers.facebook.com/) |
| **Instagram** | `META_APP_ID`, `META_APP_SECRET`, `META_REDIRECT_URI` | Meta for Developers (Uses same Meta App ID) |
| **YouTube** | `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`, `GOOGLE_REDIRECT_URI` | [Google Cloud Console](https://console.cloud.google.com/) |
| **X (Twitter)** | `X_CLIENT_ID`, `X_CLIENT_SECRET`, `X_REDIRECT_URI` | [X Developer Portal](https://developer.x.com/) |
| **WhatsApp** | `META_APP_ID`, `META_APP_SECRET`, `WHATSAPP_WEBHOOK_VERIFY_TOKEN` | [Meta Business Suite](https://business.facebook.com/) |
| **Telegram** | None required in `.env` (User inputs Bot Token from `@BotFather` directly in UI) | Official Telegram App -> `@BotFather` |

## 2. Windows 11 Running Instructions

### Start Backend
```powershell
cd "c:\Users\rkmau\Desktop\socialFlow ai\backend"
python -m uvicorn app.main:app --host 0.0.0.0 --port 8001 --reload
```

### Start Flutter Admin UI
```powershell
cd "c:\Users\rkmau\Desktop\socialFlow ai\flutter_admin"
flutter run -d windows
```

