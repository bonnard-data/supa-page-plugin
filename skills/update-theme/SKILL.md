---
description: Update site_config (theme, theme_overrides, header, footer) — lands in drafts
argument-hint: [site]
allowed-tools: mcp__plugin_supa-page-plugin_supa-page__update_site_config, mcp__plugin_supa-page-plugin_supa-page__list_sites, AskUserQuestion
model: sonnet
---

The user wants to change a site's theme, theme_overrides, header, or footer.

Resolve the site name (from `$ARGUMENTS`, conversation context, or `list_sites` + AskUserQuestion).

There's no read tool for `site_config` in v0.4.0 — ask the user what they want to change. Useful prompts:

- "Which preset? `default` or `editorial` (theme-tokens skill compares them)."
- "Brand color (CSS value for `--accent`)?"
- "Header logo + links?"
- "Footer text + links?"

Build a `site_config` patch object — only include the fields you want to change. Shape:

```
{
  title?: string,
  description?: string,
  theme?: "default" | "editorial",
  theme_overrides?: { "--accent"?: string, "--radius"?: string, ... },
  header?: { logo?: string, links?: [{label, href, variant?}] },
  footer?: { text?: string, links?: [{label, href}] }
}
```

**Pre-validate theme_overrides if you're touching them.** Run `node ${CLAUDE_PLUGIN_ROOT}/skills/theme-tokens/scripts/validate-theme-overrides.js` on the proposed object to catch unknown tokens (silently dropped at render time) and unsafe values.

Call `update_site_config({site, patch})`. The patch is merge-semantics on the top-level fields — pass only what you want to change.

Surface the result + remind the user: changes land in **drafts**. Run `/diff` to confirm, `/publish` to go live.

For the 8 overridable theme tokens, the two presets, and the customization ladder, the `theme-tokens` knowledge skill is the authoritative reference.
