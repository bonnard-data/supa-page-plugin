---
description: Edit a blog post (title, body, tags, frontmatter) — lands in drafts
argument-hint: [site] [slug]
allowed-tools: mcp__plugin_supa-page-plugin_supa-page__get_post, mcp__plugin_supa-page-plugin_supa-page__upsert_post, mcp__plugin_supa-page-plugin_supa-page__list_posts, mcp__plugin_supa-page-plugin_supa-page__list_sites, AskUserQuestion
model: sonnet
---

The user wants to edit a blog post on a supa.page site.

Resolve the site name (from `$ARGUMENTS` first token, conversation context, or `list_sites` + AskUserQuestion).

Resolve the slug (second token of `$ARGUMENTS`, or — when absent — call `list_posts({site})` and let the user pick via AskUserQuestion, or "new post"). Slug must match `[a-z0-9-]`; the slug is the URL (`/posts/<slug>`).

**Read-modify-write pattern:**

1. Call `get_post({site, slug})` to fetch the current post. Response shape: `{slug, title, date?, published, excerpt?, tags?, featured?, og_image?, body}`. 404 for a new slug — start from a fresh object with `published: false`.

2. Apply the user's intent — rewrite body Markdown, change title, flip tags, etc.

3. **Pre-validate.** Run `node ${CLAUDE_PLUGIN_ROOT}/skills/posts-and-blog/scripts/validate-frontmatter.js` against the typed post object before the upsert.

4. Call `upsert_post({site, slug, post})` with the full new post. The response includes `previewUrl` and `liveUrl`.

5. **Surface the preview URL.** Tell the user:

   > Post saved to drafts (v{version}). Preview: {previewUrl}/posts/{slug} — auto-reloads via SSE on every further edit. Live: {liveUrl}/posts/{slug} updates on `/publish`.

**Draft state vs publish state:** `published: false` is the default. A post with `published: false` is invisible on production even after `/publish` — it renders only via `?preview=1`. Both gates have to pass (`published: true` AND a successful `/publish`) for the post to be live. Flip `published: true` when ready, then `/publish`.

For frontmatter conventions and Markdown gotchas, the `posts-and-blog` knowledge skill is the authoritative reference.
