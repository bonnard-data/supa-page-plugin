---
name: list
description: Show the supa.page sites owned by the currently signed-in user
---

The user wants a list of their supa.page sites.

## What to do

1. **Read the session file:** `${XDG_CONFIG_HOME:-$HOME/.config}/supa-page/session.json`. If missing or malformed, tell the user to run `/site-signin` first.

2. **Read `server` and `session_token`.**

3. **Fetch the profile:**

   ```
   curl -sS "<server>/api/me" -H "Authorization: Bearer <session_token>"
   ```

   On 401, tell the user the session has expired and to run `/site-signin` again.

4. **Print a compact table:**

   ```
   Signed in as <user.email>

   <name>                    <prod-URL>
   <name>                    <prod-URL>
   ```

   Where `<prod-URL>` is `<server>/?site=<name>` for the local dev server or `https://<name>.supa.page` for production (derive from `server`).

5. **If there are zero sites:** print `No sites yet. Run /site-new to create your first.`

## Notes

- The `sync_token` for each site is returned by `/api/me` but should not be printed — it's a secret. Echo only the site names.
