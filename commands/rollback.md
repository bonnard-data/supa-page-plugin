---
name: rollback
description: Roll prod back to a previous published snapshot
argument-hint: [snapshot-id]
allowed-tools: Bash, AskUserQuestion
model: sonnet
disable-model-invocation: true
---

<!--
USAGE:    /rollback 2026-05-18T15-30-00.000Z-deadbeef   |   /rollback (interactive)
REQUIRES: /signin first; cwd inside a supa.page site directory
EFFECT:   Flips current.json to a prior snapshot. Does NOT touch source/.
DANGER:   disable-model-invocation is set so other agents/loops can't call
          /rollback programmatically without a human in the loop.
-->

The user wants to roll back the current supa.page site to a previous publish.

## What to do

1. **Source the shared helper + acquire the rollback lock:**

   ```bash
   source "${CLAUDE_PLUGIN_ROOT}/lib/api.sh"
   supa::ensure_deps   || exit 1
   supa::find_site_config || exit 1
   supa::ensure_signed_in || {
     echo "Run /signin first, then /rollback again." >&2
     exit 2
   }
   supa::acquire_lock /rollback || exit 1
   trap 'supa::release_lock' EXIT
   ```

   Shares the same per-project lockfile with `/publish` — `/rollback` and `/publish` can't run concurrently from the same site directory.

2. **Fetch the publish list** at `GET /api/publishes?site=<site>`:

   ```bash
   RESP="$(supa::api GET "/api/publishes?site=$SUPA_SITE")"
   STATUS="$(echo "$RESP" | head -1)"
   PAYLOAD="$(echo "$RESP" | tail -n +2)"
   ```

   Response: `{publishes: [{snapshot, timestamp, message}, ...]}` (newest first).

3. **Pick a snapshot.**

   - If `$ARGUMENTS` is non-empty and matches the snapshot id regex (`^\d{4}-\d{2}-\d{2}T\d{2}-\d{2}-\d{2}\.\d{3}Z(?:-[0-9a-f]{8})?$`), use it directly.
   - Otherwise call `AskUserQuestion` with the most recent 10 publishes as options. Each option's label is the timestamp (formatted nicely, e.g. "2026-05-18 15:30 UTC"); its description is the publish message. This is far cleaner UX than typing a long snapshot id.

4. **POST to `/api/rollback`** with `{site, snapshot}`:

   ```bash
   BODY="$(jq -cn --arg s "$SUPA_SITE" --arg snap "<snapshot>" '{site: $s, snapshot: $snap}')"
   RESP="$(supa::api POST /api/rollback "$BODY")"
   ```

5. **On 200**, audit + print:

   ```bash
   supa::audit_log rollback site="$SUPA_SITE" snapshot="<snapshot>" status=200
   ```

   ```
   ✓ Rolled back to <snapshot>
     <timestamp> — <message>
     preview:  <server>/?preview=<site>
   ```

   On 404, the snapshot id is malformed or doesn't exist — show the user the list and ask again.
   On 401, suggest `/signin`.

## Notes

- Rollback only flips the "current" pointer. It does NOT touch `source/`. Your unpublished edits in staging remain intact.
- Roll forward by publishing again (or rolling back to a later snapshot from the list).
- v0.1.3 hardened rollback: the server refuses to flip to a snapshot whose `source/` directory is missing or unreadable. If you get a 404 on a snapshot you can see in `/api/publishes`, the underlying files were manually deleted — pick a different snapshot.
- This command sets `disable-model-invocation: true` so subagents and loops can't trigger it programmatically. A human always confirms.

## Namespace clashes

If `/rollback` collides with another plugin, use `/plugin:supa-page-plugin:rollback`.
