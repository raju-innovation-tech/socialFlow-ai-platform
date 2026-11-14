# Flutter Frontend Authentication Integration

## 1. Network Layer (`flutter_admin/lib/core/network/api_client.dart`)
- Singleton `ApiClient` with Dio HTTP client.
- Base URL resolves dynamically:
  - Web & Windows Desktop: `http://127.0.0.1:8001/api/v1`
  - Android Emulator: `http://10.0.2.2:8001/api/v1`
- Request Interceptor automatically attaches:
  - `Authorization: Bearer <accessToken>`
  - `X-Workspace-ID: <activeWorkspaceId>`
- Response Interceptor transparently handles `401 Unauthorized` errors by calling `/auth/refresh` and re-executing failed requests.

## 2. State Management (`flutter_admin/lib/app/providers/auth_state_provider.dart`)
- Built on `flutter_riverpod` `NotifierProvider`.
- Exposes:
  - `login(email, password)`
  - `register(fullName, email, password, confirmPassword)`
  - `verifyEmail(email, otp)`
  - `resendOtp(email)`
  - `switchWorkspace(workspaceId)`
  - `logout()`
  - `hasPermission(permissionCode)` helper

## 3. Screen Integration
- `login_screen.dart`: Connected to real `/auth/login` endpoint with redirect to `/verify-otp` for unverified accounts.
- `register_screen.dart`: Connected to real `/auth/register` endpoint with dev OTP display toast and auto-navigation to `/verify-otp`.
- `otp_verification_screen.dart`: Connected to `/auth/verify-email` with digit entry, countdown timer, and `/auth/resend-verification`.
- `forgot_password_screen.dart` & `reset_password_screen.dart`: Connected to `/auth/forgot-password` and `/auth/reset-password`.
- `app_topbar.dart`: Interactive profile popup with multi-workspace switcher dropdown, user initials, and role indicator.
- `app_sidebar.dart`: Gated Super Admin navigation based on `isSuperAdmin`.

