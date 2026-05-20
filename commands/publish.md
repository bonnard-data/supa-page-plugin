---
name: publish
description: Publish staging to production (snapshots + flips current.json)
argument-hint: [message]
allowed-tools: Bash
model: sonnet
---

<!--
USAGE:    /publish "ship landing page v2"
REQUIRES: /signin first; cwd inside a supa.page site directory
EFFECT:   Snapshots source/ → publishes/<id>/source/, flips current.json
NOTE:     Visibility is a separate concern. New sites are private by default —
          run /visibility public to make production publicly viewable.
-->

The user wants to publish the current supa.page site's staging state to production.

## What to do

1. **Source the shared helper + acquire the publish lock:**

   ```bash
   source "${CLAUDE_PLUGIN_ROOT}/lib/api.sh"
   supa::ensure_deps   || exit 1
   supa::find_site_config || exit 1
   supa::ensure_signed_in || {
     echo "Run /signin first, then /publish again." >&2
     exit 2
   }
   supa::acquire_lock /publish || exit 1
   trap 'supa::release_lock' EXIT
   ```

   The lockfile (`.claude/supa-page-plugin.local.lock`) prevents accidentally racing yourself from two terminals. Server-side, the per-site mutex in `snapshots.ts` is the authoritative concurrency guard.

2. **Get the publish message.** Use `$ARGUMENTS` if non-empty. Otherwise ask the user (short, like a commit message). Skip the prompt if `$ARGUMENTS` looks intentional.

3. **POST to /api/publish** with `{site, message}`:

   ```bash
   BODY="$(jq -cn --arg s "$SUPA_SITE" --arg m "<message>" '{site: $s, message: $m}')"
   RESP="$(supa::api POST /api/publish "$BODY")"
   STATUS="$(echo "$RESP" | head -1)"
   PAYLOAD="$(echo "$RESP" | tail -n +2)"
   ```

4. **On 200**, response is `{snapshot, timestamp, message}`. Audit + print:

   ```bash
   SNAP="$(echo "$PAYLOAD" | jq -r .snapshot)"
   supa::audit_log publish site="$SUPA_SITE" snapshot="$SNAP" message="<message>" status=200
   ```

   ```
   ✓ Published — <message>
     snapshot: <snapshot>
     preview:  <server>/?preview=<site>
     live:     <site>.supa.page   (if visibility=public)
   ```

5. **On 401**, tell the user their session expired; suggest `/signin`. On other errors, surface the response, audit, and stop:

   ```bash
   supa::audit_log publish site="$SUPA_SITE" status="$STATUS" outcome=failed
   ```

## Notes

- `/publish` snapshots whatever is currently in `source/` on the server. If your latest edits haven't synced yet (sync hook didn't fire, server down), they won't be in the snapshot. Confirm with `/diff` first if unsure.
- **Production visibility is separate.** New sites have `visibility = 'private'`, so `<name>.supa.page` requires an org-member session. Toggle with `/visibility public`. (Use `?preview=<name>` on the apex to view the latest published state without the gate.)
- v0.1.3 changed the auth model: the plugin no longer carries a per-site token. Every command reads the BA session bearer from `~/.config/supa-page/session.json` and sends `site` in the request body.

## Namespace clashes

If `/publish` collides with another plugin, use `/plugin:supa-page-plugin:publish`.
