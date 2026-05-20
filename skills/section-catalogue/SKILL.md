---
name: section-catalogue
description: This skill should be used when authoring or editing supa.page page JSON — anything inside `<site-dir>/source/pages/*.json` or when the user asks to "add a hero section", "add a pricing block", "build a landing page", "add testimonials", "add an FAQ", "add a CTA", "list section types", "what sections does supa.page support", or mentions any of the 15 section types (hero, feature-grid, cta, quote, faq, text, post-feed, raw-embed, pricing, logos, announcement-bar, testimonials, stats, steps, team).
version: 0.1.3
---

# supa.page section catalogue

This skill is the authoritative reference for the closed section catalogue that backs every supa.page page. A page JSON file looks like:

```json
{
  "title": "Required",
  "description": "Optional <meta>",
  "sections": [ { "type": "hero", ... } ]
}
```

The renderer walks `sections[]` in order and maps each entry to its Lit component. Unknown `type` values render hidden; the platform refuses no edits but the user sees a blank slot.

## The 15 section types

| Type | Purpose |
|---|---|
| `hero` | Top-of-page introduction with title + CTAs |
| `feature-grid` | Capability tiles in 2–4 columns |
| `cta` | Stand-alone call-to-action band |
| `quote` | Single testimonial |
| `testimonials` | Multi-testimonial grid or carousel |
| `faq` | Disclosure list (auto-emits FAQPage JSON-LD) |
| `text` | Markdown prose block |
| `post-feed` | Blog index pulling from `source/posts/*.md` |
| `pricing` | Tiered pricing cards |
| `logos` | Customer-logo cloud (grid or marquee) |
| `announcement-bar` | Thin top strip — launch / status / raise |
| `stats` | Numbered tiles (e.g. "10M users") |
| `steps` | Numbered "how it works" timeline |
| `team` | People grid with photo + role |
| `raw-embed` | Customer-authored HTML escape hatch (last resort) |

## Universal section props

Every section type accepts these two layout props:

| Prop | Values | Default per-type |
|---|---|---|
| `width` | `"prose"` (36rem) / `"default"` (56rem) / `"wide"` (72rem) / `"full"` (no max) | See `references/full-section-reference.md` |
| `background` | `"bg"` / `"fg"` / `"accent"` / `"muted"` | See `references/full-section-reference.md` |

Width is an enum, not pixels. Background is a semantic token, not a hex color. To change the literal accent color, use `theme_overrides` in `site.json` (see the `theme-tokens` skill) — never inline colors.

## Naming convention — canonical vs. legacy

The catalogue uses 2026 ecosystem naming (`title`, `description`, `eyebrow`, `cta`) — but every section also accepts the pre-v0.1.3 aliases for backward compatibility:

| Canonical (preferred) | Legacy alias |
|---|---|
| `title` | `headline` (hero, cta) · `heading` (feature-grid, faq, text, post-feed, etc.) |
| `description` | `sub` (hero, cta) · `body` (feature-grid items) |
| `cta` | `button` (cta section) |
| `author` / `role` / `company` | `name` / `byline` (quote) |
| `question` / `answer` | `q` / `a` (faq items) |

**Write canonical names** in new content. Old JSON keeps rendering correctly.

## Anti-patterns

- **Do not nest sections.** Sections are flat children of `sections[]`.
- **Do not inline colors.** Use `theme_overrides` or `background` tokens.
- **Do not invent section types.** `unknown-section` renders as a hidden div. If the catalogue doesn't have what you want, the right escape hatches are `raw-embed` (for one-offs) or a customer-authored Lit component (see `custom-components` skill).
- **Do not put HTML in `text.body`.** `text.body` is **Markdown** — uses the same `marked` pipeline that renders blog posts. HTML inside Markdown works but isn't required.
- **Do not write `columns: 5` on feature-grid.** Enum is `2 | 3 | 4`; anything else clamps to 3.

## Sync-time validation

The server validates page JSON at sync time. A page rejected with a 400 carries `{error, path, field}`:

- `field: "title"` → required at root, non-empty string.
- `field: "sections"` → if present, must be an array.
- `field: "sections[i].type"` → must match `/^[a-z][a-z0-9-]{0,30}$/`.

The whole batch rejects atomically — partial writes don't land on disk. Read the error, fix the JSON, sync again.

To **pre-validate locally** before sync, run the bundled validator:

```bash
node ${CLAUDE_PLUGIN_ROOT}/skills/section-catalogue/scripts/validate-section.js path/to/page.json
```

## Editing approach

1. **Find the page file.** Sites have `source/pages/index.json` for `/`, plus `source/pages/<slug>.json` for `/<slug>` routes. Nested paths (`source/pages/work/case-a.json` → `/work/case-a`) work.
2. **Compose by section.** Start with a `hero`. Most landing pages then add `feature-grid` → `quote`/`testimonials` → `pricing` → `faq` → `cta`. The `references/composition-patterns.md` file documents proven recipes.
3. **Use the examples.** Each section type has a canonical example at `${CLAUDE_PLUGIN_ROOT}/skills/section-catalogue/examples/<type>.json` — copy + adapt rather than authoring from memory.
4. **One JSON file per page.** Don't split a single page across multiple files.

## Customization ladder

When something doesn't look right, choose the highest level that solves it:

1. **Edit a section's props** (per-instance change).
2. **Edit `theme_overrides` in `site.json`** (site-wide token change — see `theme-tokens` skill).
3. **Edit `header`/`footer` in `site.json`** (site-wide chrome — see `publishing-workflow` skill).
4. **Add a `raw-embed` section** (one-off HTML+CSS, shadow-DOM scoped).
5. **Author a custom Lit component** (rare; see `custom-components` skill).

Skip steps. Don't reach for `raw-embed` when a token override would do it.

## Additional resources

- **`references/full-section-reference.md`** — every section type, every prop, every default, with annotated JSON.
- **`references/composition-patterns.md`** — five proven landing-page recipes.
- **`examples/`** — one canonical JSON example per section type. Copy + adapt.
- **`scripts/validate-section.js`** — pre-flight validator. Same logic the server runs at `/api/sync`.
