# Tenant Isolation & API Security Architecture

## 1. Zero Trust Policy
In SocialFlow AI, the backend never blindly trusts `workspace_id` parameters sent in query parameters or request bodies:
- Every protected API endpoint passes through FastAPI dependency `get_active_workspace_member`.
- The dependency resolves the authenticated user (`get_current_active_user`) and cross-references membership in `workspace_members`.
- If the user does not possess an active membership in the target workspace, the request immediately terminates with `403 Forbidden` (`WORKSPACE_ACCESS_DENIED`).
- Super Admin accounts bypass workspace membership restrictions only when invoking dedicated `/admin/*` routes.

## 2. Cryptographic Storage Standards
- **Passwords:** `bcrypt` with cost factor 12.
- **Refresh Tokens & OTPs:** One-way SHA-256 hashes (`hashlib.sha256(token.encode()).hexdigest()`).
- **Social OAuth Tokens:** AES-128-CBC encryption via `cryptography.fernet.Fernet` with environment-controlled `CREDENTIAL_ENCRYPTION_KEY`.

## 3. Rate Limiting & Brute-Force Protection
- Login attempts are tracked in `login_attempts` with client IP and user email.
- Exceeding maximum failed attempts locks authentication attempts with exponential cooldown.
- OTP verification has a strict 3-attempt ceiling per token (`OTP_MAX_ATTEMPTS`).

