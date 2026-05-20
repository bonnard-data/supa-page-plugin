---
description: Publish staging to production (snapshots source/, flips current.json)
argument-hint: [site] [message]
allowed-tools: mcp__plugin_supa-page-plugin_supa-page__publish_site, mcp__plugin_supa-page-plugin_supa-page__list_sites, AskUserQuestion
model: sonnet
---

The user wants to publish the current state of a site to production.

Resolve the site name first:
- If `$ARGUMENTS` contains a site name (first token), use it
- Otherwise call `list_sites` and either pick from conversation context or ask via AskUserQuestion

Resolve the message (everything after the site name in `$ARGUMENTS`):
- If non-empty, use as the publish message
- Otherwise use AskUserQuestion (header "Publish message", description "Short — like a commit message, e.g. 'Editorial theme refresh'") to gather one

Call `mcp__plugin_supa-page-plugin_supa-page__publish_site` with `{site, message}`. Present the returned `snapshot` id + the preview/live URLs.

Note: `publish_site` snapshots whatever the server already has. If the agent just edited files locally, it must call `sync_files` first to push them to the server. `diff_site` is the cheapest way to confirm what's staged.
