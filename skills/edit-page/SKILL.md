---
description: Edit a page (sections, title, description, og_image) — lands in drafts
argument-hint: [site] [slug]
allowed-tools: mcp__plugin_supa-page-plugin_supa-page__get_page, mcp__plugin_supa-page-plugin_supa-page__upsert_page, mcp__plugin_supa-page-plugin_supa-page__validate_block, mcp__plugin_supa-page-plugin_supa-page__list_blocks, mcp__plugin_supa-page-plugin_supa-page__get_block, mcp__plugin_supa-page-plugin_supa-page__list_pages, mcp__plugin_supa-page-plugin_supa-page__list_sites, AskUserQuestion
model: sonnet
---

The user wants to edit a page on a supa.page site.

Resolve the site name (from `$ARGUMENTS` first token, conversation context, or `list_sites` + AskUserQuestion).

Resolve the slug (second token of `$ARGUMENTS`, or — when absent — call `list_pages({site})` and let the user pick via AskUserQuestion). For a brand-new page, the slug is whatever the user wants; conventions: `index` (root `/`), `about`, `pricing`, `work/case-a`.

**Read-modify-write pattern:**

1. Call `get_page({site, slug})` to fetch the current page object. Response shape: `{slug, title, description?, sections: Section[], og_image?}`. For a new slug the tool returns 404 — start from `{slug, title: "...", sections: []}`.

2. Apply the user's intent — change a section's copy, add/remove sections, swap order, set the title. For unknown block types, consult MCP discovery: `list_blocks` for the catalogue, `get_block({type})` for one block's schema + examples. See the `section-catalogue` knowledge skill for composition guidance.

3. **Pre-validate every section.** For each section in the proposed page, call `mcp__plugin_supa-page-plugin_supa-page__validate_block({type, data})`. Each call returns `{ok, errors: [{path, expected, got, hint}]}`. Fix every error before upsert — block schemas are `.strict()` and the server-side `upsert_page` re-validates and rejects the whole call atomically on failure.

4. Call `upsert_page({site, slug, page})` with the full new page object. The whole object replaces the existing draft row — there is no field-level patch API. The response includes `previewUrl` and `liveUrl`.

5. **Surface the preview URL.** Tell the user:

   > Edits saved to drafts (v{version}). Preview: {previewUrl} — opens immediately; the tab auto-reloads via SSE on every further edit. Live (public): {liveUrl} updates on `/publish`.

   The preview URL is the killer iteration loop — encourage the user to open it before further edits so they can see changes in real time.

After the upsert, summarise what changed and offer the next moves: `/diff` to see what's staged across the site, `/publish` to promote to main (live URL updates immediately), `/discard-changes` to throw the draft away.
