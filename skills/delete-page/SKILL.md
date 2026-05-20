---
description: Delete a page (lands in drafts; takes effect on next publish)
argument-hint: <site> <slug>
allowed-tools: mcp__plugin_supa-page-plugin_supa-page__delete_page, mcp__plugin_supa-page-plugin_supa-page__list_sites, mcp__plugin_supa-page-plugin_supa-page__list_pages, AskUserQuestion
model: sonnet
disable-model-invocation: true
---

The user wants to delete a page. `disable-model-invocation: true` — destructive; a human always confirms.

Parse `$ARGUMENTS` as `<site> <slug>`. Resolve either side via context or `list_sites` / `list_pages` + AskUserQuestion if missing.

**Confirm before deleting.** Use AskUserQuestion (header "Confirm deletion", description "Delete page `<slug>` from `<site>`? This stages the deletion as a draft; it takes effect when you next /publish.") with two options: "Yes, delete" / "Cancel".

If confirmed, call `mcp__plugin_supa-page-plugin_supa-page__delete_page` with `{site, slug}`. The deletion lands in drafts — the page is still live on `<site>.supa.page` until `/publish`. Surface the result + remind the user to `/diff` and `/publish`.

You cannot delete the `index` page on a site that has no other pages — `delete_page` will refuse.
