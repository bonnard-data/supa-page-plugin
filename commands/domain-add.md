---
name: domain-add
description: Register a custom domain (apex or subdomain) for the current site
argument-hint: [domain]
allowed-tools: Bash
model: sonnet
---

<!--
USAGE:    /domain-add www.example.com
REQUIRES: /signin first; cwd inside a supa.page site directory
EFFECT:   POST /api/domains; returns DNS configuration instructions.
-->

The user wants to register a custom domain.

## What to do

1. **Source the shared helper:**

   ```bash
   source "${CLAUDE_PLUGIN_ROOT}/lib/api.sh"
   supa::ensure_deps      || exit 1
   supa::find_site_config || exit 1
   supa::ensure_signed_in || {
     echo "Run /signin first, then /domain-add again." >&2
     exit 2
   }
   ```

2. **Take the domain** from `$ARGUMENTS`. If empty, ask the user.

3. **Validate format** (RFC 1035-ish — basic shape check before hitting the API):

   ```bash
   if ! [[ "$DOMAIN" =~ ^([a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z]{2,}$ ]]; then
     echo "supa.page: '$DOMAIN' doesn't look like a valid domain. Examples: example.com, www.example.com, blog.acme.io" >&2
     exit 1
   fi
   ```

4. **POST `/api/domains`** with `{site, domain}`:

   ```bash
   BODY="$(jq -cn --arg s "$SUPA_SITE" --arg d "$DOMAIN" '{site: $s, domain: $d}')"
   RESP="$(supa::api POST /api/domains "$BODY")"
   STATUS="$(echo "$RESP" | head -1)"
   PAYLOAD="$(echo "$RESP" | tail -n +2)"
   ```

5. **On 200**, the response looks like:

   ```json
   {
     "domain": "example.com",
     "site": "<site>",
     "status": "pending_dns",
     "cname_target": "routing.supa.page",
     "apex_a_records": ["178.105.150.207"],
     "observed": [],
     "instructions": { "apex": "...", "subdomain": "..." }
   }
   ```

   Decide which DNS shape applies based on the domain:
   - Apex (e.g. `example.com`, `acme.io`) → A record(s)
   - Subdomain (`www.example.com`, `blog.acme.io`) → CNAME

   For a **subdomain**:
   ```
   ✓ Added <domain>

   Add this DNS record at your registrar:
     Type:   CNAME
     Name:   <subdomain-label>   (e.g. www, blog, app)
     Value:  routing.supa.page   (from cname_target)
   ```

   For an **apex**:
   ```
   ✓ Added <domain>

   Add this DNS record at your registrar:
     Type:   A
     Name:   @
     Value:  <apex_a_records[0]>
   ```

   Always finish with:
   ```
   HTTPS issues automatically once DNS propagates (usually < 5 min).
   Run /domain-list to check status.
   ```

6. **Error handling:**
   - 409: already claimed by another site. Surface the message.
   - 400: invalid domain shape. Surface the message.
   - 401: session expired — suggest `/signin`.

7. **Audit the result** (whether success or failure):

   ```bash
   supa::audit_log domain-add site="$SUPA_SITE" domain="$DOMAIN" status="$STATUS"
   ```

## Notes

- Each subdomain is its own registration. `example.com` and `www.example.com` are
  separate. Register both if you want both.
- Status meanings (state machine from the API):
  - `pending_dns` — DNS hasn't reached us yet
  - `dns_verified` — DNS points at us; Caddy will mint a cert on first request
  - `issuing_cert` — cert issuance in flight
  - `active` — serving traffic
  - `error_dns` — DNS resolves but points elsewhere
  - `error_cert` — cert issuance failed (LE rate-limited or CAA blocked)
