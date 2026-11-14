# Token Management & Rotation Architecture

## 1. Access Tokens (JWT)
- **Algorithm:** HMAC SHA-256 (`HS256`)
- **Lifetime:** 30 minutes (configurable via `ACCESS_TOKEN_EXPIRE_MINUTES`)
- **Claims Included:**
  - `sub`: User UUID
  - `jti`: Unique token identifier (prevents replay)
  - `email`: Normalized user email
  - `is_super_admin`: Platform Super Admin flag
  - `iat`: Issued at timestamp
  - `exp`: Expiration timestamp
  - `iss`: Token issuer (`socialflow-api`)
  - `aud`: Token audience (`socialflow-client`)

## 2. Refresh Token Rotation (RTR) & Theft Detection
SocialFlow AI implements RFC 6819 compliant refresh token rotation with token family tracking:

1. **Token Generation:** 48 cryptographically secure random bytes generated via `secrets.token_urlsafe(48)`.
2. **One-Way Hashing:** Only the SHA-256 digest is stored in the database (`refresh_tokens.token_hash`).
3. **Token Families:** Each login initializes a `token_family` UUID.
4. **Rotation on Refresh (`POST /api/v1/auth/refresh`):**
   - The presented refresh token is marked `is_used = True` and revoked.
   - A new refresh token is issued within the same `token_family`.
   - A new access token is returned.
5. **Replay / Theft Detection:**
   - If an already-used refresh token is replayed, the system detects a token reuse attack.
   - The entire `token_family` is immediately revoked in the database.
   - An audit security alert is generated (`token_reuse_detected`).
   - All active sessions within that family are terminated.

