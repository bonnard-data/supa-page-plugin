---
name: list
description: List the supa.page sites the signed-in user owns
allowed-tools: Bash
model: haiku
---

<!--
USAGE:    /list
REQUIRES: /signin first
EFFECT:   Read-only. GET /api/me; renders the sites array.
-->

The user wants a list of their supa.page sites.

## What to do

1. **Source the shared helper:**

   ```bash
   source "${CLAUDE_PLUGIN_ROOT}/lib/api.sh"
   supa::ensure_deps   || exit 1
   supa::ensure_signed_in || {
     echo "Not signed in. Run /signin to authorize this machine." >&2
     exit 2
   }
   ```

   (No site config needed — this is a global view.)

2. **Fetch the profile** at `GET /api/me`:

   ```bash
   RESP="$(supa::api GET /api/me)"
   STATUS="$(echo "$RESP" | head -1)"
   PAYLOAD="$(echo "$RESP" | tail -n +2)"
   ```

3. **Render the table.** v0.1.3 response shape:

   ```json
   {
     "user": { "id", "email", "created_at", "welcomed_at" },
     "org_id": "...",
     "sites": [{ "name", "visibility", "created_at" }]
   }
   ```

   Note: `sync_token` is no longer returned (the field is gone from the DB as of v0.1.3). Auth happens via the BA session.

   ```
   Signed in as <user.email>

   <name>          (<visibility>)    https://<name>.supa.page
   <name>          (<visibility>)    https://<name>.supa.page
   ```

   Show `<visibility>` from the row (`public` or `private`).

4. **If `sites` is empty:** print `No sites yet. Run /new <name> to create your first.`

5. **On 401**: session expired — tell the user to re-run `/signin`.
