# SocialFlow AI – Authentication Architecture (Phase 3)

## 1. Overview
SocialFlow AI implements a zero-trust, stateless JWT authentication system paired with stateful refresh token rotation, brute-force rate limiting, and cryptographic email verification OTPs.

## 2. Authentication Lifecycle

### A. User Registration (`POST /api/v1/auth/register`)
1. **Email Normalization:** Trims whitespace and converts to lower case (`alex.rivera@example.com`).
2. **Duplicate Detection:** Queries `User.normalized_email` to ensure email uniqueness across all tenants.
3. **Password Security:** Hashes plaintext passwords using `bcrypt` (12 work factor rounds). Plaintext passwords are never logged or stored.
4. **Tenant Initialization:** Automatically creates an initial default workspace (e.g. `Alex Rivera's Workspace`) and binds the user as `owner`.
5. **OTP Generation:** Issues a 6-digit cryptographically secure numeric OTP (`secrets.randbelow`), stores its SHA-256 hash in `email_verification_tokens`, and sets a 15-minute expiration.

### B. Email OTP Verification (`POST /api/v1/auth/verify-email`)
- Matches the SHA-256 hash of the submitted OTP against active, non-expired tokens.
- Increments `attempts_count`. If invalid attempts exceed `max_attempts` (default: 3), the token is locked.
- Upon success, marks `user.email_verified = True` and activates the account (`account_status = "active"`).

### C. Login (`POST /api/v1/auth/login`)
- Verifies password hash using `bcrypt.checkpw`.
- Verifies account status is `active` and `email_verified` is true.
- Issues:
  - Short-lived Access Token (JWT, 30-minute validity) signed with `HS256`.
  - Rotating Refresh Token (cryptographically random 48-byte token, SHA-256 hashed in database, 7-day validity).
- Writes an audit log record into `audit_logs` tracking IP address, user-agent, and timestamp.

### D. Password Reset Flow
1. **Forgot Password (`POST /api/v1/auth/forgot-password`):** Generates a 6-digit reset OTP and stores its SHA-256 hash with a 15-minute TTL.
2. **Reset Password (`POST /api/v1/auth/reset-password`):** Validates the OTP hash, hashes the new password with bcrypt, and invalidates all existing user refresh tokens and active sessions to guarantee session revocation.

