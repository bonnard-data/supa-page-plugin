---
name: status
description: Show the current site's name, server, sign-in state, and basic health
allowed-tools: Bash
model: haiku
---

<!--
USAGE:    /status
EFFECT:   Read-only. Prints the local site config + a /health probe.
-->

Show the user the status of the supa.page site they're working in.

## What to do

1. **Source the shared helper:**

   ```bash
   source "${CLAUDE_PLUGIN_ROOT}/lib/api.sh"
   supa::ensure_deps || exit 1
   ```

2. **Locate the site config.** If `supa::find_site_config` fails, tell the user "Not in a supa.page site directory. Run `/new <name>` to create one, or `cd` into an existing site."

3. **Check sign-in state.** Run `supa::ensure_signed_in`. On success, fetch the user via `GET /api/me` for context. On failure, print "Not signed in — run `/signin`."

4. **Print the snapshot:**

   ```
   Site:    <SUPA_SITE>
   Server:  <SUPA_SERVER>
   Preview: <SUPA_SERVER>/?preview=<SUPA_SITE>
   Live:    <SUPA_SITE>.supa.page   (if visibility=public)
   Signed in as: <email>
   ```

5. **Health probe.** `curl -sf -o /dev/null -w '%{http_code}' "$SUPA_SERVER/health"`. 200 → "Server: ok". Anything else → "Server: unreachable (<status>)".
