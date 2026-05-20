---
description: Show the preview URL for a site (renders from current publish)
argument-hint: [site]
allowed-tools: mcp__plugin_supa-page-plugin_supa-page__get_site, mcp__plugin_supa-page-plugin_supa-page__list_sites, AskUserQuestion, Bash
model: haiku
---

The user wants the preview URL for a site.

Resolve the site name (from `$ARGUMENTS`, conversation context, or `list_sites` + AskUserQuestion).

Optionally call `get_site` to confirm it exists and show its current visibility. Then print:

```
Preview: https://supa.page/?preview=<site>
Live:    https://<site>.supa.page   (if visibility=public)
```

If the user is on macOS, you may offer to `open https://supa.page/?preview=<site>` for them via Bash.
