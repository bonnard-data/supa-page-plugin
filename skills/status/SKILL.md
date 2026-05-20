---
description: Show one site's current state (visibility, URLs, last publish)
argument-hint: [site]
allowed-tools: mcp__plugin_supa-page-plugin_supa-page__get_site, mcp__plugin_supa-page-plugin_supa-page__list_sites, AskUserQuestion
model: haiku
---

The user wants the current state of a site.

If `$ARGUMENTS` is non-empty, treat it as the site name. Otherwise call `list_sites` and either pick the obvious one from conversation context, or use AskUserQuestion to let the user choose.

Then call `mcp__plugin_supa-page-plugin_supa-page__get_site` with that name and present: name, visibility, org, and the live + preview URLs.
