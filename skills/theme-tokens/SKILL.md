---
name: theme-tokens
description: This skill should be used when adjusting a supa.page site's visual look — colors, fonts, radius, borders, prose width. Triggers include "change the accent color", "use a different font", "use Spectral", "make it more rounded", "darker theme", "use brand color #...", "use the editorial theme", "what themes are available", "override theme tokens", "site.json theme_overrides", or any request to restyle the appearance globally without touching individual sections.
version: 0.1.3
---

# supa.page theme tokens

This skill governs the **visual layer** — colors, fonts, radius, borders, layout widths. Two surfaces:

1. **Preset themes** (`site.json.theme: "default" | "editorial"`) — full token bundles maintained by the platform.
2. **`theme_overrides`** in `site.json` — per-site CSS-var overrides on top of the preset. Bounded to an 8-token allow-list; everything outside is silently dropped.

## The whole API (it's small)

```json
{
  "title": "My site",
  "theme": "editorial",
  "theme_overrides": {
    "--accent": "#7c3aed",
    "--radius": "0.75rem"
  }
}
```

That's it. No `custom_css` field. No theme JSON for the customer to author. The preset gives you the whole token bundle; overrides tweak the 8 highest-leverage tokens.

## The 8 overridable tokens

| Token | What it controls |
|---|---|
| `--accent` | The brand color. CTAs, accent text, eyebrows, FAQ open icon, link color in prose. 70%+ of customer overrides target this. |
| `--accent-fg` | The text/icon color on top of `--accent` (e.g. white-on-purple). Required when accent is dark and the default accent-fg (white) reads wrong. |
| `--radius` | Border radius for cards, buttons, inputs. `0` → sharp, `0.5rem` → modern soft, `9999px` → pill. |
| `--font-sans` | Body + UI font. Default theme uses system Inter; the editorial preset binds this to Spectral. |
| `--font-serif` | Serif face. Used by components that explicitly need serif (rare). |
| `--font-mono` | Code blocks. |
| `--border` | Card edge color. Subtle on light themes, bolder on high-contrast looks. |
| `--width-prose` | Article body width. Default 36rem — narrow it for tighter long-form. |

**Everything else is silently dropped.** `--bg`, `--fg`, `--muted`, `--leading`, `--tracking-tight`, `--width-default`, `--width-wide`, `--max-width` etc. are baked into the preset and not user-overridable. (Exposing them invites unreadable contrast and broken vertical rhythm — see the audit memo in `references/why-bounded.md`.)

## Two presets

| Preset | Look | Body font | Accent |
|---|---|---|---|
| `default` | Neutral, system-Inter, sharp-ish | Inter | Black (#18181b) |
| `editorial` | Heavier, serif, warm cream background | Spectral | Crimson (#c44536) |

Use the **`theme-tokens` examples** dir to see both presets with and without overrides applied.

## Values: hex, OKLCH, rgb(), font stacks

Pass whatever CSS the browser accepts. The renderer doesn't normalise — what you write is what lands in the `:root { ... }` block. Common shapes:

```jsonc
{ "--accent": "#7c3aed" }                        // hex
{ "--accent": "oklch(0.55 0.25 280)" }           // OKLCH (2026-idiomatic)
{ "--accent": "rgb(124 58 237)" }                // rgb
{ "--font-sans": "'Geist Sans', system-ui" }     // font stack
{ "--radius": "0.75rem" }                        // length
{ "--width-prose": "32rem" }                     // length
```

Use hex during early iteration (paste from Figma) — switch to OKLCH if you need perceptually-even lightness ramps later.

## Safety rules

The override emitter rejects:

- **Values containing `;`, `{`, or `}`** — would let an override escape the `:root` declaration and inject sibling CSS rules.
- **Values over 200 chars** — guards against accidentally pasting a giant data URL.
- **Non-string values** — only strings get emitted.

The renderer drops the offending override silently and continues. If your customisation isn't showing up, check the value doesn't contain `;` and isn't an array or object.

## Loading custom fonts

The presets bring their own webfonts (editorial preloads Spectral via Google Fonts). For overrides that point at a custom face, **load the font in site.json's chrome OR via a `<link>` you embed using a `raw-embed` section** — the override JSON itself can't add `<link>` tags.

Two-step recipe:

1. Add a `raw-embed` section near the top of the page with the font preload:

   ```json
   {
     "type": "raw-embed",
     "name": "geist-font-loader",
     "html": "<link rel='stylesheet' href='https://cdn.example.com/geist-sans-1.0.css'>"
   }
   ```

2. Set the override in site.json:

   ```json
   { "theme_overrides": { "--font-sans": "'Geist Sans', system-ui, sans-serif" } }
   ```

Better long-term: use a self-hosted font + add the preload via the platform's chrome — coming in a future milestone.

## Customization ladder reminder

Theme tokens are step **#2** in the customization ladder:

1. Edit a section's props (per-instance change).
2. **Edit `theme_overrides` in `site.json`** (site-wide token change — this skill).
3. Edit `header`/`footer` in `site.json` (site-wide chrome — see `publishing-workflow` skill).
4. Add a `raw-embed` section (one-off HTML+CSS, shadow-DOM scoped — see `custom-components` skill).
5. Author a custom Lit component (rare — see `custom-components` skill).

If a customer asks "make all buttons rounder", that's `--radius`. If they ask "make the CTA on the hero rounder", that's a section-level prop (not currently exposed for `--radius`, so it's actually a token override anyway). When in doubt, go higher in the ladder.

## Pre-flight validation

The bundled validator checks an entire `site.json` (or just a `theme_overrides` object) against the allow-list:

```bash
node ${CLAUDE_PLUGIN_ROOT}/skills/theme-tokens/scripts/validate-theme-overrides.js path/to/site.json
```

Reports unknown tokens (dropped at render time) + values that would be rejected for safety (stylesheet escape attempts, oversize).

## Additional resources

- **`references/why-bounded.md`** — explains why the override surface is 8 tokens, not 80.
- **`references/preset-comparison.md`** — side-by-side of `default` vs. `editorial` so you can pick the right starting preset.
- **`examples/site.json.default.json`** — minimal site.json on the default preset, no overrides.
- **`examples/site.json.editorial.json`** — editorial preset, all-Spectral.
- **`examples/site.json.purple-brand.json`** — default preset with an accent override.
- **`scripts/validate-theme-overrides.js`** — pre-flight validator.
