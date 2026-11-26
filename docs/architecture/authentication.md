# Authentication

Admin sessions and passkeys, subscriber magic links, API tokens.

## Authentication
- **Admin**: session-based (signed cookie, 14-day expiry). The `Authentication` concern owns cookie → `Session` resumption (`resume_session`, memoized via a `Current.session` short-circuit) and is included once on `ApplicationController`, so both admin (`current_user`) and identity (`IdentityAuthentication#current_identity`) lookups share a single `sessions` query per request.
- **Admin Passkeys**: optional WebAuthn/passkey sign-in alongside password. Configured via `WEBAUTHN_ORIGIN` and `WEBAUTHN_RP_ID` env vars. Managed at `/admin/passkeys`.
- **Subscribers**: passwordless magic-link (15-minute token expiry). `Subscriber.subscribe_or_sign_in!` uses `assign_auth_token` before a new subscriber's first save so signup writes the row once; `generate_auth_token!` assigns and saves.
- **MCP/API**: Bearer token (`prose_`-prefixed, SHA256 digest stored)
