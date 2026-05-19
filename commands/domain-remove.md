---
name: domain-remove
description: Unregister a custom domain from the current site
---

The user wants to remove a custom domain from the current site.

## What to do

1. Find the nearest `.supa-page.json` by walking up from cwd. If none, tell the user and stop.
2. Read `server` and `token` from `.supa-page.json`.
3. Take the domain from `$ARGUMENTS`. If empty, ask.
4. DELETE `<server>/api/domains/<domain>` with Bearer auth:

   ```
   curl -sS -X DELETE "<server>/api/domains/<domain>" \
     -H "Authorization: Bearer <token>"
   ```

5. On 200, print `✓ Removed <domain>`.
6. On 404, tell the user the domain wasn't bound to this site.

## Notes

- This only removes the binding in supa.page. DNS at your registrar is unchanged — clean that up separately.
- Caddy may serve the old cert briefly until its cache clears (a few minutes).
