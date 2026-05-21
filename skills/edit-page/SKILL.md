---
description: Edit a page (sections, title, description, og_image) — lands in drafts
argument-hint: [site] [slug]
allowed-tools: mcp__plugin_supa-page-plugin_supa-page__get_page, mcp__plugin_supa-page-plugin_supa-page__upsert_page, mcp__plugin_supa-page-plugin_supa-page__list_pages, mcp__plugin_supa-page-plugin_supa-page__list_sites, AskUserQuestion
model: sonnet
---

The user wants to edit a page on a supa.page site.

Resolve the site name (from `$ARGUMENTS` first token, conversation context, or `list_sites` + AskUserQuestion).

Resolve the slug (second token of `$ARGUMENTS`, or — when absent — call `list_pages({site})` and let the user pick via AskUserQuestion). For a brand-new page, the slug is whatever the user wants; conventions: `index` (root `/`), `about`, `pricing`, `work/case-a`.

**Read-modify-write pattern:**

1. Call `get_page({site, slug})` to fetch the current page object. Response shape: `{ slug, title, description?, sections: Section[], og_image? }`. (For a new slug the tool returns 404 — start from `{ slug, title: "...", sections: [] }`.)
2. Apply the user's intent — change a section's copy, add/remove sections, swap order, set the title.
3. **Pre-validate.** Run `node ${CLAUDE_PLUGIN_ROOT}/skills/section-catalogue/scripts/validate-section.js` against the proposed object to catch malformed sections before the upsert.
4. Call `upsert_page({site, slug, page})` with the full new page object. The whole object replaces the existing draft row — there is no field-level patch API.

Surface the result + remind the user: edits land in **drafts**. Run `/diff` to see what's staged, `/publish` to promote drafts to main (live URL updates immediately), `/discard-changes` to throw the draft away.

For page composition guidance (section catalogue, recipes), the `section-catalogue` knowledge skill is the authoritative reference.
