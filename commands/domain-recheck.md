---
name: domain-recheck
description: Force a DNS re-check on a custom domain
argument-hint: [domain]
allowed-tools: Bash
model: haiku
---

<!--
USAGE:    /domain-recheck www.example.com
REQUIRES: /signin first
EFFECT:   POST /api/domains/:domain/recheck — re-runs the DNS probe immediately
          instead of waiting for the background poller.
-->

The user wants to force a DNS re-check on a domain. Use this when:

- A domain was just added and DNS was configured since
- A domain is in `error_dns` or `pending_dns` and the user just fixed records
- They want to verify everything before sharing the URL

## What to do

1. **Source the shared helper:**

   ```bash
   source "${CLAUDE_PLUGIN_ROOT}/lib/api.sh"
   supa::ensure_deps   || exit 1
   supa::ensure_signed_in || {
     echo "Run /signin first." >&2
     exit 2
   }
   ```

   (No site config required — domain ownership is resolved on the server.)

2. **Take the domain** from `$ARGUMENTS`. If empty, run `/domain-list` first to show options and ask.

3. **POST `/api/domains/<domain>/recheck`:**

   ```bash
   RESP="$(supa::api POST "/api/domains/$DOMAIN/recheck")"
   STATUS="$(echo "$RESP" | head -1)"
   PAYLOAD="$(echo "$RESP" | tail -n +2)"
   ```

4. **Render the result.** Response:

   ```json
   {
     "domain": "example.com",
     "status": "dns_verified",
     "observed": ["178.105.150.207"],
     "expected": ["178.105.150.207"],
     "error": null
   }
   ```

   - `dns_verified` / `active` → `✓ example.com is configured correctly. HTTPS will be issued on the first request (if not already active).`
   - `pending_dns` → `⏳ example.com isn't resolving yet. DNS may still be propagating.`
   - `error_dns` → `⚠ example.com resolves to <observed>, but we expected <expected>. Check DNS records at your registrar.`

## Notes

- The platform runs background DNS checks every few minutes. `/domain-recheck` gives you immediate feedback when you've just made a DNS change.
