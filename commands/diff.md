---
name: diff
description: Show changes between staging (source) and the current publish
allowed-tools: Bash
model: haiku
---

<!--
USAGE:    /diff
REQUIRES: /signin first; cwd inside a supa.page site directory
EFFECT:   Read-only. GET /api/diff?site=<name>.
-->

Show what's different between staged edits and the live publish.

## What to do

1. **Source the shared helper:**

   ```bash
   source "${CLAUDE_PLUGIN_ROOT}/lib/api.sh"
   supa::ensure_deps   || exit 1
   supa::find_site_config || exit 1
   supa::ensure_signed_in || {
     echo "Run /signin first, then /diff again." >&2
     exit 2
   }
   ```

2. **GET `/api/diff?site=<site>`:**

   ```bash
   RESP="$(supa::api GET "/api/diff?site=$SUPA_SITE")"
   STATUS="$(echo "$RESP" | head -1)"
   PAYLOAD="$(echo "$RESP" | tail -n +2)"
   ```

3. **Render the summary.** Response shape: `{added: [...], modified: [...], deleted: [...]}` (paths relative to `source/`).

   ```
   Changes vs prod:
     + <path>     (added — N files)
     ~ <path>     (modified — N files)
     - <path>     (deleted — N files)
   ```

   One line per file. If all three lists are empty: `No changes — staging matches prod.`
