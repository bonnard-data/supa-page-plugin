---
description: Delete a blog post (lands in drafts; takes effect on next publish)
argument-hint: <site> <slug>
allowed-tools: mcp__plugin_supa-page-plugin_supa-page__delete_post, mcp__plugin_supa-page-plugin_supa-page__list_sites, mcp__plugin_supa-page-plugin_supa-page__list_posts, AskUserQuestion
model: sonnet
disable-model-invocation: true
---

The user wants to delete a blog post. `disable-model-invocation: true` — destructive; a human always confirms.

Parse `$ARGUMENTS` as `<site> <slug>`. Resolve either side via context or `list_sites` / `list_posts` + AskUserQuestion if missing.

**Confirm before deleting.** Use AskUserQuestion (header "Confirm deletion", description "Delete post `<slug>` from `<site>`? This stages the deletion as a draft; it takes effect when you next /publish.") with two options: "Yes, delete" / "Cancel".

If confirmed, call `mcp__plugin_supa-page-plugin_supa-page__delete_post` with `{site, slug}`. The deletion lands in drafts — the post is still live until `/publish`. Surface the result + remind the user to `/diff` and `/publish`.

If you only want to unpublish a post (rather than delete it forever), `/edit-post` and flip `published: false` instead.
