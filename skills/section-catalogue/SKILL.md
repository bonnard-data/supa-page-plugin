---
name: section-catalogue
description: This skill should be used when authoring or editing supa.page pages — anything that goes through `upsert_page` / the `Page.sections[]` shape — or when the user asks to "add a hero", "add a pricing block", "build a landing page", "add testimonials", "add an FAQ", "add a CTA", "what blocks exist", "list block types", "what sections does supa.page support". The renderer ships a 24-block catalogue (hero, features, pricing, testimonials, faq, cta, stats, logos, nav, footer, plus interactive blocks); use `list_blocks` for the live inventory.
version: 0.5.0
---

# supa.page block catalogue

This skill governs how to author pages on supa.page. The renderer accepts a fixed catalogue of block types; each has a strict Zod schema. Compose pages by selecting from the catalogue, filling typed props, and pushing via `upsert_page`.

## The authoring loop

Follow this loop for every page edit:

1. **Discover** the catalogue when needed via `mcp__plugin_supa-page-plugin_supa-page__list_blocks`. Returns `{type, title, summary, whenToUse}` for every block. Use this to choose which blocks fit the brief.

2. **Inspect one block** via `mcp__plugin_supa-page-plugin_supa-page__get_block` with `{type: "<block-type>"}`. Returns the full JSON Schema, defaults, and 1–3 canonical examples. The examples are the prop-shape ground truth — copy and adapt them rather than guessing field names.

3. **Compose** the page object: `{title, description?, og_image?, sections: [...]}`. Each section is `{type, ...block-specific-props}`. Universal layout props that the page renderer reads (not the block): `width`, `background`.

4. **Validate** before upsert via `mcp__plugin_supa-page-plugin_supa-page__validate_block` with `{type, data}` for each section. Returns `{ok, errors: [{path, expected, got, hint}]}`. Fix every error returned — the schema is `.strict()` and rejects unknown keys. If an error mentions a field name you don't recognise, re-fetch `get_block({type})` for the canonical schema; don't guess.

5. **Upsert** via `mcp__plugin_supa-page-plugin_supa-page__upsert_page` with `{site, slug, page}`. The response includes `previewUrl` and `liveUrl` — surface both to the user.

6. **Surface the preview URL** to the user. The preview URL renders from `*_draft` tables and auto-reloads via SSE when any draft row changes. The user can keep the tab open while iterating. The live URL only updates on `publish_site`.

## Block categories

The 24 blocks group into eight categories. Use `list_blocks` for the current set; this is a navigation aid:

| Category | Blocks |
|---|---|
| Hero | `hero-centered`, `hero-split-image`, `hero-stats`, `hero-minimal` |
| Features | `feature-grid`, `features-grid-6` |
| Pricing | `pricing-cards-3`, `pricing-simple` |
| CTA | `cta` (centered), `cta-banner` |
| Social proof | `testimonials-grid-3`, `testimonial-quote-big`, `logos-row` |
| Narrative | `faq`, `text` (Markdown prose), `steps-numbered` |
| Stats | `stats-row-4`, `stats-with-context` |
| Team + chrome | `team-grid`, `nav-simple`, `footer-simple` |
| Interactive | `announcement-bar`, `cookie-banner`, `newsletter-form` |

## Universal section props

Every section accepts these two layout props (handled by the page renderer, not the block schema):

| Prop | Values | Default |
|---|---|---|
| `width` | `"prose" \| "default" \| "wide" \| "full"` | per-block default |
| `background` | `"bg" \| "fg" \| "accent" \| "muted" \| "soft" \| "strong" \| "inverse" \| "accent-soft"` | per-block default |

Backgrounds are semantic tokens, not literal colours. To change brand colour, use `theme_overrides` via `update_site_config` (see the `theme-tokens` skill) — never inline hex values in section props.

## Page anatomies

Five proven recipes (see `references/composition-patterns.md` for details):

1. **Indie SaaS landing**: `nav-simple` → `announcement-bar?` → `hero-centered` → `logos-row` → `features-grid-3` → `testimonials-grid-3` → `pricing-cards-3` → `faq` → `cta` → `footer-simple`
2. **Dev tool / open source**: `nav-simple` → `hero-stats` → `features-grid-6` → `steps-numbered` → `stats-row-4` → `testimonial-quote-big` → `cta` → `footer-simple`
3. **B2B / sales-led**: `nav-simple` → `hero-split-image` → `logos-row` → `features-grid-3` → `testimonials-grid-3` → `cta-banner` → `footer-simple`
4. **Newsletter / writer**: `nav-simple` → `hero-minimal` → `text` (about) → `newsletter-form` → `footer-simple`
5. **Single product**: `hero-split-image` → `features-grid-6` → `pricing-simple` → `faq` → `cta-banner`

## Anti-patterns

- **Do not invent block types.** Unknown types render as `<div hidden data-unknown-section="...">`. Call `list_blocks` for the canonical set.
- **Do not nest sections.** `sections[]` is flat.
- **Do not inline colours.** Use `theme_overrides` or `background` tokens.
- **Do not put HTML in `text.body`.** It is Markdown (the same `marked` pipeline as posts).
- **Do not pass unknown keys.** Block schemas are `.strict()`; unknown keys are rejected with a `validate_block` error.
- **Do not skip validation.** Schemas are strict; `validate_block` catches every wrong-shape mistake before the upsert.

## Authoring a new page

For a brand-new slug, `get_page` returns 404 — start from `{slug, title: "...", sections: []}` and build up.

The `upsert_page` write replaces the entire draft row. There is no field-level patch. Always: `get_page` → modify locally → `upsert_page` (full object).

## Customisation ladder

When something doesn't look right, climb in this order. Stop at the first level that solves it:

1. **Edit a section's props** (per-instance change — `upsert_page`).
2. **Edit `theme_overrides` via `update_site_config`** (site-wide token change — see `theme-tokens` skill).
3. **Edit `header` / `footer` via `update_site_config`** (site-wide chrome — alternatively, use `nav-simple` + `footer-simple` blocks as page-level sections).

Custom-authored Lit components are not supported in v0.5; that path was removed when the renderer switched from Lit to frameworkless SSR. The 24-block catalogue plus theme overrides cover ~99% of real customer needs.

## Additional resources

- **`references/composition-patterns.md`** — five recipes worked out in detail, with section ordering and rationale.
- **`examples/full-landing-page.json`** — one complete canonical page object showing multi-section composition.
- **`mcp__plugin_supa-page-plugin_supa-page__list_blocks`** — runtime catalogue.
- **`mcp__plugin_supa-page-plugin_supa-page__get_block`** — runtime schema + examples for one type.
- **`mcp__plugin_supa-page-plugin_supa-page__validate_block`** — runtime validator (canonical pre-flight).
- **`plugin/shared/block-schemas.json`** — offline snapshot of all 24 schemas + examples (regenerated by `bun run build:schemas` in the supa-page repo).
