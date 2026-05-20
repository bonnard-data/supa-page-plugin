---
name: visibility
description: Set site visibility — public lets anyone view it, private gates to org members
argument-hint: [public|private]
allowed-tools: Bash, AskUserQuestion
model: sonnet
---

<!--
USAGE:    /visibility public      | /visibility private | /visibility (asks)
REQUIRES: /signin first; cwd inside a supa.page site directory
EFFECT:   PUT /api/sites/:name/visibility with {visibility: 'public'|'private'}
NOTE:     Future enum values (password, allowlist, sso) will extend cleanly.
-->

The user wants to change a site's visibility.

## What to do

1. **Source the shared helper:**

   ```bash
   source "${CLAUDE_PLUGIN_ROOT}/lib/api.sh"
   supa::ensure_deps   || exit 1
   supa::find_site_config || exit 1
   supa::ensure_signed_in || {
     echo "Run /signin first, then /visibility again." >&2
     exit 2
   }
   ```

2. **Determine the target value.**

   - If `$ARGUMENTS` is `public` or `private`, use it directly.
   - Otherwise call `AskUserQuestion`:

     | Question | Header | Options |
     |---|---|---|
     | "Who should be able to view <site>.supa.page?" | "Visibility" | **Public** (Anyone can view) / **Private** (Only signed-in org members can view) |

3. **PUT to `/api/sites/<site>/visibility`** with `{"visibility": "<value>"}`:

   ```bash
   BODY="$(jq -cn --arg v "<value>" '{visibility: $v}')"
   RESP="$(supa::api PUT "/api/sites/$SUPA_SITE/visibility" "$BODY")"
   STATUS="$(echo "$RESP" | head -1)"
   PAYLOAD="$(echo "$RESP" | tail -n +2)"
   ```

4. **On 200**, audit + print:

   ```bash
   supa::audit_log visibility site="$SUPA_SITE" value="<value>" status=200
   ```

   ```
   ✓ <site>.supa.page is now <value>.
   ```

   For `public`, add: "Anyone with the URL can view it." For `private`, add: "Visitors are redirected to sign in; only org members get through."

5. **On 401**, suggest `/signin`. On 400, surface the validation message.

## Notes

- Visibility is a long-lived site property — distinct from publishing. You don't need to re-publish after toggling it.
- The preview URL (`<server>/?preview=<site>`) is always reachable by the site's owners and ignores visibility.
- Future modes: `password` (shared password gate) and `allowlist` (per-email gate) will land in later releases via the same enum endpoint.

## Namespace clashes

If `/visibility` collides with another plugin, use `/plugin:supa-page-plugin:visibility`.
