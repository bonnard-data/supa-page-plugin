---
name: signin
description: Sign in to supa.page (browser flow — supports email code, GitHub, or Google)
---

The user wants to sign in to their supa.page account.

This command uses the **OAuth 2.0 Device Authorization Grant** (RFC 8628) — the
standard pattern used by `gh auth login`, AWS CLI, Stripe CLI, etc. The user
authorizes the CLI from their browser (where they can pick any sign-in method:
email code, GitHub, or Google), and the CLI polls until the session token is
available.

## What to do

1. **Server:** use `$SUPA_PAGE_SERVER` if set, otherwise `https://supa.page`.
   The dashboard host is `app.<apex>` — derive it: if server is `https://supa.page`
   then dashboard is `https://app.supa.page`. For localhost dev the server *is*
   the dashboard host.

2. **Request a device code:**

   ```bash
   curl -sS -X POST "<server>/api/auth/device/code" \
     -H "Content-Type: application/json" \
     -d '{"client_id":"supa-page-plugin"}'
   ```

   Response:
   ```json
   {
     "device_code": "<long opaque>",
     "user_code": "ABCD-1234",
     "verification_uri": "<dashboard>/device",
     "verification_uri_complete": "<dashboard>/device?user_code=ABCD-1234",
     "expires_in": 900,
     "interval": 5
   }
   ```

3. **Tell the user to authorize in their browser:**

   ```
   To sign in, visit:
     <verification_uri>

   And enter this code:
     <user_code>
   ```

   If you can detect the user's platform and they have `open` (macOS) or
   `xdg-open` (Linux) or `start` (Windows), offer to open the
   `verification_uri_complete` URL for them — it pre-fills the code.

4. **Poll for the access token** every `interval` seconds (default 5):

   ```bash
   curl -sS -X POST "<server>/api/auth/device/token" \
     -H "Content-Type: application/json" \
     -d "$(jq -cn --arg dc "<device_code>" '{
       grant_type: "urn:ietf:params:oauth:grant-type:device_code",
       device_code: $dc,
       client_id: "supa-page-plugin"
     }')"
   ```

   Response shapes:
   - Success: `{"access_token":"<token>","token_type":"Bearer", ...}`
   - Pending: `{"error":"authorization_pending"}` → keep polling
   - Slow down: `{"error":"slow_down"}` → increase interval by 5s
   - Denied: `{"error":"access_denied"}` → stop, tell user they denied
   - Expired: `{"error":"expired_token"}` → stop, tell user to run `/signin` again

   Stop after `expires_in` seconds even if no terminal status.

5. **On success: save the session.** Use
   `${XDG_CONFIG_HOME:-$HOME/.config}/supa-page/session.json`:

   ```json
   {
     "server": "<server>",
     "session_token": "<access_token>"
   }
   ```

   `mkdir -p` the dir first. Set the file to `chmod 600`.

   Fetch the user via `/api/me` to confirm sign-in:

   ```bash
   curl -sS "<server>/api/me" -H "Authorization: Bearer <access_token>"
   ```

   Then print: `✓ Signed in as <email>. Run /list to see your sites.`

## Notes

- The session token is BA's bearer token. ~30-day TTL by default. Same token works
  for both CLI and web (cookies + bearer headers share the `session` table).
- Use `/signout` to revoke it before the TTL.
- If the user has never signed in before, they'll be bounced through the
  dashboard's first-time-signin flow (email/GitHub/Google) before they can
  approve the device. They'll also see a "What's your workspace called?"
  step on first sign-in — that's normal.
