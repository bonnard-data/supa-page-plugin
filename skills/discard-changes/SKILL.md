---
description: Throw away draft changes (page, post, site_config, or all)
argument-hint: [site] [page|post|site_config|all] [slug]
allowed-tools: mcp__plugin_supa-page-plugin_supa-page__discard_changes, mcp__plugin_supa-page-plugin_supa-page__diff_site, mcp__plugin_supa-page-plugin_supa-page__list_sites, AskUserQuestion
model: sonnet
disable-model-invocation: true
---

The user wants to discard staged draft changes. Destructive; a human always confirms.

Parse `$ARGUMENTS`:
- First token = site name (resolve via context or `list_sites` + AskUserQuestion if absent)
- Second token = scope: `page` | `post` | `site_config` | `all` (default `all`)
- Third token (only when scope is `page` or `post`) = slug

**Always show the diff first.** Call `diff_site({site})` and surface the pages/posts/site_config that would be reverted. If the diff is empty, tell the user "No draft changes — nothing to discard." and stop.

**Confirm.** Use AskUserQuestion to confirm. Header "Discard drafts", description summarising what gets thrown away (e.g. "Discard 3 modified pages, 1 added post, and site_config changes from `<site>`? This cannot be undone.").

If confirmed, call `mcp__plugin_supa-page-plugin_supa-page__discard_changes` with:
- `{site}` for "all"
- `{site, kind: "page", slug}` for a single page
- `{site, kind: "post", slug}` for a single post
- `{site, kind: "site_config"}` for theme/header/footer drafts

Surface the result. Live main is unchanged — only the draft rows are reset.
