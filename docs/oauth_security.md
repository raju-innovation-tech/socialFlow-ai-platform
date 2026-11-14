# OAuth 2.0 Security Architecture & Best Practices

## 1. Zero Plaintext Token Storage
All access tokens, refresh tokens, and bot tokens are encrypted at rest using AES-128-CBC via Fernet with `ENCRYPTION_KEY`. Tokens are never logged, never returned in API responses, and never accessible to unauthorized workspaces.

## 2. CSRF State Tokens
- Every OAuth request generates a cryptographically random 32-byte token (`secrets.token_urlsafe(32)`).
- The state token is bound to the initiating `workspace_id`, `platform`, and `redirect_uri` in table `oauth_states`.
- Tokens have a strict 15-minute TTL.
- Once validated during callback exchange, the token is consumed and immediately deleted from the database to prevent replay attacks.

## 3. PKCE (Proof Key for Code Exchange)
- Implemented for X (Twitter) API v2 and modern LinkedIn OpenID Connect.
- Uses `code_challenge_method=S256` with high-entropy 48-byte `code_verifier`.
- Protects against authorization code interception in browser environments.

## 4. Redirect URI Validation
Redirect URIs are strictly validated against pre-registered backend and frontend endpoints. Open redirects and wildcards are disallowed.

