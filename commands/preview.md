---
name: preview
description: Open the preview URL for the current site (renders from source/)
allowed-tools: Bash
model: haiku
---

<!--
USAGE:    /preview
EFFECT:   Read-only. Constructs the preview URL and opens it in the default browser.
-->

The user wants to preview the current supa.page site's staged content.

## What to do

1. **Source the shared helper:**

   ```bash
   source "${CLAUDE_PLUGIN_ROOT}/lib/api.sh"
   supa::find_site_config || exit 1
   ```

   (No `/signin` required — the preview URL is open within the platform's visibility rules.)

2. **Build the URL:** `${SUPA_SERVER}/?preview=${SUPA_SITE}`.

3. **Open the browser:**

   ```bash
   case "$(uname)" in
     Darwin) open "$URL" ;;
     Linux)  xdg-open "$URL" ;;
     *)      start "$URL" 2>/dev/null || true ;;
   esac
   ```

4. **Always print the URL** in case the browser launch fails.

## Notes

- Preview renders from `source/` (your staged edits). The production URL `https://<site>.supa.page` shows the latest published snapshot.
- If the site has `visibility=private`, production requires an org-member session. Preview never does — it's gated only by knowing the URL.
