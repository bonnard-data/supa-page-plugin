---
name: rollback
description: Roll prod back to a previous published snapshot
---

The user wants to roll back the current supa.page site to a previous publish.

## What to do

1. Find the nearest `.supa-page.json`. If none, tell the user and stop.
2. Read `server` and `token` from `.supa-page.json`.
3. Fetch the publish list:

   ```
   curl -sS "<server>/api/publishes" -H "Authorization: Bearer <token>"
   ```

   Response: `{publishes: [{snapshot, timestamp, message}, ...]}` (newest first).

4. If `$ARGUMENTS` is non-empty and matches a snapshot id (e.g. `2026-05-18T15-30-00.000Z`), use it directly. Otherwise, show the user the most recent 10 publishes numbered 1–10 (with timestamp and message), and ask which one to roll back to.

5. POST to `<server>/api/rollback`:

   ```
   curl -sS -X POST "<server>/api/rollback" \
     -H "Authorization: Bearer <token>" \
     -H "Content-Type: application/json" \
     -d "$(jq -cn --arg s "<snapshot>" '{snapshot: $s}')"
   ```

6. On 200, print:
   ```
   ✓ Rolled back to <snapshot>
     <timestamp> — <message>
     prod URL: <server>/?site=<name>
   ```

## Notes

- Rollback only flips the "current" pointer. It does NOT touch `source/`. Your unpublished edits in staging remain intact.
- Roll forward by publishing again (or rolling back to a later snapshot from the list).
