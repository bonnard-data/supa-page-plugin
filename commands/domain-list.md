---
name: domain-list
description: List custom domains for the current site with DNS + cert status
allowed-tools: Bash
model: haiku
---

<!--
USAGE:    /domain-list
REQUIRES: /signin first; cwd inside a supa.page site directory
EFFECT:   Read-only. GET /api/domains?site=<name>.
-->

The user wants to see custom domains registered for this site.

## What to do

1. **Source the shared helper:**

   ```bash
   source "${CLAUDE_PLUGIN_ROOT}/lib/api.sh"
   supa::ensure_deps      || exit 1
   supa::find_site_config || exit 1
   supa::ensure_signed_in || {
     echo "Run /signin first." >&2
     exit 2
   }
   ```

2. **GET `/api/domains?site=<site>`:**

   ```bash
   RESP="$(supa::api GET "/api/domains?site=$SUPA_SITE")"
   STATUS="$(echo "$RESP" | head -1)"
   PAYLOAD="$(echo "$RESP" | tail -n +2)"
   ```

3. **Render the rows.** Response shape:

   ```json
   {
     "domains": [
       { "domain": "example.com", "status": "active",      "last_checked_at": ..., "last_error": null, "password_protected": false },
       { "domain": "www.example.com", "status": "pending_dns", "last_checked_at": ..., "last_error": "...", "password_protected": false }
     ]
   }
   ```

   Render:

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
   - `dns_verified` / `issuing_cert` → `⏳`
   - `pending_dns` → `⏳`
   - `error_dns` / `error_cert` → `⚠`
   - `disabled` → `–`

   Prefix with `🔒` if `password_protected: true`.

4. **If empty:**

   ```
   No custom domains registered. Use /domain-add to add one.
   ```

5. After printing, suggest `/domain-recheck <domain>` for any non-active domains to force a DNS re-check.
