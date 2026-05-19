---
name: domain-list
description: List custom domains for the current site with status
---

The user wants to see all custom domains registered for this site, along with
their DNS-verification + cert status.

## What to do

1. Find the nearest `.supa-page.json` by walking up from cwd. If none, tell the user and stop.
2. Read `server` and `token` from `.supa-page.json`.
3. GET `<server>/api/domains` with Bearer auth:

   ```bash
   curl -sS "<server>/api/domains" -H "Authorization: Bearer <token>"
   ```

4. Response shape:

   ```json
   {
     "domains": [
       {
         "domain": "example.com",
         "status": "active",
         "last_checked_at": 1779190000000,
         "last_error": null,
         "password_protected": false
       },
       {
         "domain": "www.example.com",
         "status": "pending_dns",
         "last_checked_at": 1779190000000,
         "last_error": "Domain does not resolve. DNS may still be propagating.",
         "password_protected": false
       }
     ]
   }
   ```

5. Print one row per domain with a status indicator. Suggested format:

   ```
   ✓ example.com         (active)
   ⏳ www.example.com    (pending_dns)
                          DNS may still be propagating.
   ⚠ blog.example.com    (error_dns)
                          Domain resolves to 1.2.3.4 but expected 178.105.150.207.
   🔒 app.example.com    (active, password-protected)
   ```

   Status → indicator:
   - `active` → `✓`
   - `dns_verified` / `issuing_cert` → `⏳` (in progress)
   - `pending_dns` → `⏳`
   - `error_dns` / `error_cert` → `⚠`
   - `disabled` → `–`

   Prefix with `🔒` if `password_protected: true`.

6. If the list is empty:

   ```
   No custom domains registered. Use /domain-add to add one.
   ```

7. After printing, suggest `/domain-recheck <domain>` for any non-active domains
   to force a DNS re-check.
