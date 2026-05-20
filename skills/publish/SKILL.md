---
description: Promote drafts to main — updates the live site immediately
argument-hint: [site] [message]
allowed-tools: mcp__plugin_supa-page-plugin_supa-page__publish_site, mcp__plugin_supa-page-plugin_supa-page__list_sites, AskUserQuestion
model: sonnet
---

The user wants to publish their drafts to production.

Resolve the site name first:
- If `$ARGUMENTS` contains a site name (first token), use it
- Otherwise call `list_sites` and either pick from conversation context or ask via AskUserQuestion

Resolve the message (everything after the site name in `$ARGUMENTS`):
- If non-empty, use as the publish message
- Otherwise use AskUserQuestion (header "Publish message", description "Short — like a commit message, e.g. 'Editorial theme refresh'") to gather one

Call `mcp__plugin_supa-page-plugin_supa-page__publish_site` with `{site, message}`. Surface the response (publish id + summary of what was promoted) and the live URL `https://<site>.supa.page`.

What publish does in v0.4.0: promotes the `*_draft` rows for pages, posts, and site_config to main, then re-renders the static HTML served by Caddy. **The live URL updates immediately** — no snapshot history, no rollback. If a publish was a mistake, edit forward and publish again.

`diff_site` is the cheapest way to confirm what's staged before publishing.
