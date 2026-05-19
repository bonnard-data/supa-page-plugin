---
name: domain-add
description: Register a custom domain for the current site (apex or subdomain)
---

The user wants to register a custom domain.

## What to do

1. Find the nearest `.supa-page.json` by walking up from cwd. If none, tell the user and stop.
2. Read `server` and `token` from `.supa-page.json`.
3. Take the domain from `$ARGUMENTS`. If empty, ask.
4. POST to `<server>/api/domains` with Bearer auth:

   ```bash
   curl -sS -X POST "<server>/api/domains" \
     -H "Authorization: Bearer <token>" \
     -H "Content-Type: application/json" \
     -d "$(jq -cn --arg d "<domain>" '{domain: $d}')"
   ```

5. On 200, response looks like:

   ```json
   {
     "domain": "example.com",
     "site": "<site>",
     "status": "pending_dns",
     "cname_target": "routing.supa.page",
     "apex_a_records": ["178.105.150.207"],
     "observed": [],
     "instructions": {
       "apex": "If this is an apex (e.g. example.com), add A records pointing to 178.105.150.207.",
       "subdomain": "If this is a subdomain (e.g. www.example.com), add a CNAME pointing to routing.supa.page."
     }
   }
   ```

   Decide which DNS shape applies based on the domain shape:
   - Apex (e.g. `example.com`, `acme.io`) → A record(s)
   - Subdomain (`www.example.com`, `blog.acme.io`) → CNAME

   For a **subdomain**, print:
   ```
   ✓ Added <domain>

   Add this DNS record at your registrar:
     Type:   CNAME
     Name:   <subdomain-label>   (e.g. www, blog, app)
     Value:  <cname_target>      (from response)
   ```

   For an **apex**, print:
   ```
   ✓ Added <domain>

   Add this DNS record at your registrar:
     Type:   A
     Name:   @
     Value:  <apex_a_records[0]>   (from response)
   ```

   Always finish with:
   ```
   HTTPS issues automatically after DNS propagates (usually < 5 min).
   Run /domain-list to check status.
   ```

6. On 409 (already claimed by another site), surface the error and stop.

## Notes

- Each subdomain is its own registration. `example.com` and `www.example.com` are
  separate domains — register both if you want both.
- Status meanings (state machine from the API):
  - `pending_dns` — DNS hasn't reached us yet
  - `dns_verified` — DNS points at us; Caddy will mint a cert on first request
  - `issuing_cert` — cert issuance in flight
  - `active` — serving traffic
  - `error_dns` — DNS resolves but points elsewhere
  - `error_cert` — cert issuance failed (LE rate-limited or CAA blocked)
