---
name: preview
description: Open the staging preview URL for the current site in the default browser
---

The user wants to preview the current supa.page site's staging state in a browser.

## What to do

1. Find the nearest `.supa-page.json`. If none, tell the user and stop.
2. Read `site` and `server` from `.supa-page.json`.
3. Construct the preview URL: `<server>/?preview=<site>`
4. Print the URL and try to open it in the default browser:
   - macOS: `open "<url>"`
   - Linux: `xdg-open "<url>"`
   - Windows: `start "<url>"`
5. Tell the user the URL regardless, in case the browser open fails.

## Notes

- This URL renders from `source/` (what's currently staged). Production URL `<server>/?site=<name>` shows the last published snapshot.
