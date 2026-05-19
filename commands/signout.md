---
name: signout
description: Sign out of supa.page on this machine (revokes the session server-side too)
---

The user wants to sign out of their supa.page account.

## What to do

1. **Read the local session file:** `${XDG_CONFIG_HOME:-$HOME/.config}/supa-page/session.json`. If it doesn't exist, tell the user "Not signed in" and stop.

2. **Read `server` and `session_token` from it.**

3. **Revoke server-side:**

   ```
   curl -sS -X POST "<server>/auth/signout" \
     -H "Authorization: Bearer <session_token>"
   ```

4. **Delete the local file:** `rm ~/.config/supa-page/session.json` (use the actual resolved path).

5. **Confirm:** print `✓ Signed out.`
