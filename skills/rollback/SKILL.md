---
description: Roll prod back to a previous published snapshot
argument-hint: [site] [snapshot-id]
allowed-tools: mcp__plugin_supa-page-plugin_supa-page__rollback_site, mcp__plugin_supa-page-plugin_supa-page__list_publishes, mcp__plugin_supa-page-plugin_supa-page__list_sites, AskUserQuestion
model: sonnet
disable-model-invocation: true
---

The user wants to roll back a site's `current` pointer to an earlier publish. `disable-model-invocation: true` — subagents and background loops can't invoke this; a human always confirms.

Resolve the site name (explicit, context, or `list_sites` + AskUserQuestion).

Resolve the snapshot:
- If the second token of `$ARGUMENTS` matches `^\d{4}-\d{2}-\d{2}T\d{2}-\d{2}-\d{2}\.\d{3}Z(-[0-9a-f]{8})?$`, use it directly.
- Otherwise call `list_publishes` for the site. Use AskUserQuestion with one option per publish (label: nicely-formatted timestamp like "2026-05-18 15:30 UTC", description: the publish message). Don't list the current/topmost publish as a rollback target — it's a no-op.

Call `mcp__plugin_supa-page-plugin_supa-page__rollback_site` with `{site, snapshot}`. Surface the response.

Rollback flips the `current` pointer only — `source/` (staging) is unchanged. Unpublished edits remain intact.
