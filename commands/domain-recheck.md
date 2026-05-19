---
name: domain-recheck
description: Re-check DNS status for a custom domain (force refresh)
---

The user wants to force a DNS re-check on a domain. Use this when:

- A domain was just added and DNS was set up since
- A domain is in `error_dns` or `pending_dns` state and the user just fixed DNS
- They want to verify everything is working before sharing the URL

## What to do

1. Find the nearest `.supa-page.json` by walking up from cwd. If none, tell the user and stop.
2. Read `server` and `token` from `.supa-page.json`.
3. Take the domain from `$ARGUMENTS`. If empty, prompt or fall back to running
   `/domain-list` and ask which to recheck.
4. POST `<server>/api/domains/<domain>/recheck` with Bearer auth:

   ```bash
   curl -sS -X POST "<server>/api/domains/<domain>/recheck" \
     -H "Authorization: Bearer <token>"
   ```

5. Response:

   ```json
   {
     "domain": "example.com",
     "status": "dns_verified",
     "observed": ["178.105.150.207"],
     "expected": ["178.105.150.207"],
     "error": null
   }
   ```

   Print:

   - On `dns_verified` or `active`:
     ```
     ✓ example.com is configured correctly.
       HTTPS will be issued on the first request (if not already active).
     ```
   - On `pending_dns`:
     ```
     ⏳ example.com isn't resolving yet. DNS may still be propagating.
     ```
   - On `error_dns`:
     ```
     ⚠ example.com resolves to <observed>, but we expected <expected>.
       Check your DNS records at your registrar.
     ```

## Notes

- The platform also runs background checks on its own — but this command gives
  the user immediate feedback while waiting on DNS propagation.
