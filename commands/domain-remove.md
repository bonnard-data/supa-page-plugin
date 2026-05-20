---
name: domain-remove
description: Unregister a custom domain from the current site
argument-hint: [domain]
allowed-tools: Bash
model: sonnet
disable-model-invocation: true
---

<!--
USAGE:    /domain-remove www.example.com
REQUIRES: /signin first; cwd inside a supa.page site directory
EFFECT:   DELETE /api/domains/:domain
DANGER:   disable-model-invocation set — removing a production domain shouldn't
          happen programmatically. Customers must confirm interactively.
-->

The user wants to remove a custom domain from the current site.

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

2. **Take the domain** from `$ARGUMENTS`. If empty, ask.

3. **Validate format:**

   ```bash
   if ! [[ "$DOMAIN" =~ ^([a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z]{2,}$ ]]; then
     echo "supa.page: '$DOMAIN' is not a valid domain shape." >&2
     exit 1
   fi
   ```

4. **DELETE `/api/domains/<domain>`:**

   ```bash
   RESP="$(supa::api DELETE "/api/domains/$DOMAIN")"
   STATUS="$(echo "$RESP" | head -1)"
   ```

5. **Status handling:**
   - 200 → `✓ Removed <domain>`.
   - 404 → "Domain not registered, or not owned by you. Run `/domain-list` to confirm."
   - 401 → suggest `/signin`.

6. **Audit:**

   ```bash
   supa::audit_log domain-remove site="$SUPA_SITE" domain="$DOMAIN" status="$STATUS"
   ```

## Notes

- This only removes the binding in supa.page. DNS at your registrar is unchanged — clean it up separately if you no longer want the domain to resolve.
- Caddy may serve the old cert briefly until its cache clears (a few minutes).
