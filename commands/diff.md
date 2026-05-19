---
name: diff
description: Show what's changed between staging (source) and the current published snapshot
---

The user wants to see what's different between their staged edits and what's live in production.

## What to do

1. Find the nearest `.supa-page.json`. If none, tell the user and stop.
2. Read `server` and `token` from `.supa-page.json`.
3. GET `<server>/api/diff` with Bearer auth:

   ```
   curl -sS "<server>/api/diff" -H "Authorization: Bearer <token>"
   ```

4. Response: `{added: [...], modified: [...], deleted: [...]}` (paths relative to `source/`).

5. Print a compact summary:
   ```
   Changes vs prod:
     + <path>     (added — N files)
     ~ <path>     (modified — N files)
     - <path>     (deleted — N files)
   ```
   Use one line per file. If all three lists are empty, print "No changes — staging matches prod."
