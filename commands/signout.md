---
name: signout
description: Sign out of supa.page on this machine (revokes the session server-side)
allowed-tools: Bash
model: haiku
disable-model-invocation: true
---

<!--
USAGE:    /signout
EFFECT:   POST /api/auth/sign-out (BA) with the session bearer; deletes the
          local ~/.config/supa-page/session.json file.
DANGER:   disable-model-invocation set so background loops can't sign you
          out unexpectedly.
-->

The user wants to sign out of their supa.page account.

## What to do

1. **Read the local session file:** `${XDG_CONFIG_HOME:-$HOME/.config}/supa-page/session.json`. If it doesn't exist, tell the user "Not signed in" and stop.

2. **Read `server` and `session_token` from it.**

3. **Revoke server-side via Better Auth:**

   ```
   curl -sS -X POST "<server>/api/auth/sign-out" \
     -H "Authorization: Bearer <session_token>"
   ```

   (The pre-v0.1.3 path `<server>/auth/signout` was the legacy magic-link
   endpoint; it doesn't recognise BA session tokens and silently no-ops.)

4. **Delete the local file:** `rm ~/.config/supa-page/session.json` (use the actual resolved path).

5. **Audit + confirm:**

   ```bash
   source "${CLAUDE_PLUGIN_ROOT}/lib/api.sh"
   supa::audit_log signout server="<server>"
   ```

   Then print `✓ Signed out.`
