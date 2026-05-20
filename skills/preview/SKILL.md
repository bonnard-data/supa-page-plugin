---
description: Show the preview URL for a site (draft view with live SSE updates)
argument-hint: [site]
allowed-tools: mcp__plugin_supa-page-plugin_supa-page__get_site, mcp__plugin_supa-page-plugin_supa-page__list_sites, AskUserQuestion, Bash
model: haiku
---

The user wants the preview URL for a site.

Resolve the site name (from `$ARGUMENTS`, conversation context, or `list_sites` + AskUserQuestion).

Optionally call `get_site` to confirm it exists and show its current visibility. Then print:

```
Preview (drafts): https://<site>.supa.page/?preview=1
Live (main):      https://<site>.supa.page
```

`?preview=1` reads from the `*_draft` tables — so any edit you make via `upsert_page` / `upsert_post` / `update_site_config` is visible on reload. The renderer also opens an SSE stream on that URL: when a draft row changes, the open page reloads automatically. Live (main) only updates when you `/publish`.

If visibility is `private`, the live URL gates non-org-members but the preview URL is still reachable.

If the user is on macOS, you may offer to `open https://<site>.supa.page/?preview=1` for them via Bash.
