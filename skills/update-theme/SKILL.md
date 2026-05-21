---
description: Update site_config (theme, theme_overrides, header, footer) — lands in drafts
argument-hint: [site]
allowed-tools: mcp__plugin_supa-page-plugin_supa-page__update_site_config, mcp__plugin_supa-page-plugin_supa-page__list_sites, AskUserQuestion
model: sonnet
---

The user wants to change a site's theme, theme_overrides, header, or footer.

Resolve the site name (from `$ARGUMENTS`, conversation context, or `list_sites` + AskUserQuestion).

There's no read tool for `site_config` in v0.5 — ask the user what they want to change. Useful prompts:

- "Which preset? `default` or `editorial` (theme-tokens skill compares them)."
- "Brand colour (CSS value for `--accent`)?"
- "Header logo + links?"
- "Footer text + links?"

Build a `site_config` patch object — only include fields you want to change. Shape:

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

Call `update_site_config({site, config})`. The response includes `previewUrl` and `liveUrl`.

**Surface the preview URL.** Tell the user:

> Site config saved to drafts (v{version}). Preview: {previewUrl} — auto-reloads via SSE; refresh the open preview tab to see the new theme. Live (public): {liveUrl} updates on `/publish`.

Theme changes propagate to every page on the site (it's a site-wide token change, not a per-page edit). Mention this if the user expected per-page scope.

For the token reference (which 8 tokens are overridable, why others aren't), the `theme-tokens` knowledge skill is authoritative.
