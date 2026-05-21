---
description: List every block type the renderer supports — discovery surface for page authoring
allowed-tools: mcp__plugin_supa-page-plugin_supa-page__list_blocks, mcp__plugin_supa-page-plugin_supa-page__get_block, AskUserQuestion
model: haiku
---

The user wants to see what blocks the supa.page renderer supports.

Call `mcp__plugin_supa-page-plugin_supa-page__list_blocks` (no arguments). It returns every block type with `{type, title, summary, whenToUse}`.

Print the result grouped by category (hero / features / pricing / cta / social-proof / narrative / stats / chrome / interactive), one line per block: `<type> — <one-line summary>`.

If the user follows up with a specific type ("show me hero-centered", "what fields does pricing-cards-3 take"), call `mcp__plugin_supa-page-plugin_supa-page__get_block({type})` and surface the JSON Schema + examples.

For authoring guidance (composition recipes, anti-patterns), the `section-catalogue` knowledge skill is the authoritative reference.
