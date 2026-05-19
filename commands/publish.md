---
name: publish
description: Publish the current staging state to production (snapshots source/ and flips the live symlink)
---

The user wants to publish the current supa.page site's staging state to production.

## What to do

1. Find the nearest `.supa-page.json` by walking up from the cwd. If none, tell the user "Not in a supa.page site directory." and stop.
2. Read `server` and `token` from `.supa-page.json`.
3. Use `$ARGUMENTS` as the publish message. If empty, ask the user for one (short, like a commit message). Skip the prompt if `$ARGUMENTS` looks intentional (even one word is fine).
4. POST to `<server>/api/publish` with Bearer auth:

   ```
   curl -sS -X POST "<server>/api/publish" \
     -H "Authorization: Bearer <token>" \
     -H "Content-Type: application/json" \
     -d "$(jq -cn --arg m "<message>" '{message: $m}')"
   ```

5. On 200, response is `{snapshot, timestamp, message}`. Print:
   ```
   ✓ Published — <message>
     snapshot: <snapshot>
     prod URL: <server>/?site=<name>
   ```
6. On error, surface the response and stop.

## Notes

- Publish snapshots whatever is currently in `source/` on the server. If your latest edits haven't synced yet (sync hook didn't fire, server down), they won't be in the snapshot. Confirm with `/site-diff` first if unsure.
