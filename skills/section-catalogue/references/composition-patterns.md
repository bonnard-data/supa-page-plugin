# Composition patterns

Five proven page recipes built from the v0.5 catalogue. Copy and adapt rather than authoring from memory.

The block names below are canonical types as returned by `list_blocks`. Confirm against the live `list_blocks` output before authoring — the registry is the source of truth.

## 1. Indie SaaS landing page

Default starting point for a one-product page.

```
nav-simple            ← chrome
announcement-bar?     ← optional, for launches / raises
hero-centered         ← title + dual CTA + optional badge
logos-row             ← "Trusted by"
feature-grid          ← 3 capability tiles with optional icons
testimonials-grid-3   ← 3 named, on-page testimonials
pricing-cards-3       ← 3 tiers, one featured
faq                   ← 4–8 questions
cta                   ← final "Start free"
footer-simple         ← chrome
```

Order rationale: hero → social proof (logos) → product (features) → trust (testimonials) → price → objection-handling (faq) → re-ask for conversion → footer.

## 2. Open-source / dev tool

Different rhythm — devs want capability + code before pricing.

```
nav-simple
hero-stats             ← title + 3-stat hook (downloads, stars, contributors)
features-grid-6        ← 6 capability cells with inline icons
steps-numbered         ← "Three commands to install"
stats-row-4            ← stars / downloads / latency / uptime
testimonial-quote-big  ← one oversized pull-quote
cta                    ← "Read the docs" / "Star on GitHub"
footer-simple
```

Skip pricing entirely or defer to a separate `/pricing` page.

## 3. B2B / sales-led

Heavier on logos and case studies; pricing usually deferred.

```
nav-simple
hero-split-image       ← copy on left, product shot on right (LCP candidate)
logos-row              ← enterprise customer names
features-grid-3        ← bigger tiles for fewer, deeper capabilities
testimonials-grid-3    ← 3 quotes with rating + case study link
stats-with-context     ← 2-column narrative-framed stats
cta-banner             ← accent-bg "Schedule a demo" strip
footer-simple
```

Put `pricing-cards-3` on a dedicated `/pricing` slug and link from the CTA.

## 4. Newsletter / writer landing

Minimal — get them to subscribe.

```
nav-simple
hero-minimal           ← name + tagline + single CTA, left-aligned narrow
text                   ← Markdown — about the writer + topic
newsletter-form        ← inline subscribe (interactive block)
footer-simple
```

(A dedicated `post-grid` block surfacing the latest blog posts on the home page is on the roadmap. For now, link to `/posts` from a `text` body or via `nav-simple`.)

## 5. Single-product page

For one product or one feature.

```
nav-simple
hero-split-image       ← product shot, accent variant CTA
features-grid-6        ← deeper feature exposition
pricing-simple         ← single-tier card
testimonial-quote-big
faq
cta-banner             ← accent strip closer
footer-simple
```

## Chrome blocks: header + footer

`nav-simple` and `footer-simple` are blocks like any other — render them as `sections[0]` and `sections[N-1]` for now. A first-class chrome surface (separate `site_config.header` / `.footer` that propagates across every page) ships later; using them as sections works today and stays compatible with that future migration.

## Composition rules of thumb

- **Aim for 6–10 sections per landing page.** Fewer feels thin; more is hard to scan.
- **One `hero-*` per page.** Multiple h1s break SEO and reader expectations.
- **One closing CTA (`cta` or `cta-banner`).** Two CTAs split conversion focus.
- **Match section width to content density.** Wide for grids, narrow for prose.
- **Don't repeat block types adjacent to themselves.** Two `feature-grid` back-to-back read as one section.

## Anti-recipes

- **Hero stuffing.** Eyebrow + badge + title + description + 2 CTAs + microcopy + image all crammed in. Pick the 3–4 elements that earn space. A single CTA outperforms two confused ones.
- **Hero + nothing else.** Visitors who don't convert from the hero have nowhere else to land. Add at least one `feature-grid` or `testimonial-quote-big`.
- **Pricing first.** Visitors don't know what they're paying for yet. Pricing belongs after the value pitch.
- **Three `testimonial-quote-big` in a row.** Reads as padding. Use `testimonials-grid-3` for multiple, `testimonial-quote-big` for one anchor quote.
- **Inline CSS to "match the brand".** Use `theme_overrides` via `update_site_config`. The block schemas don't accept colour values.

## Voice consistency

Before authoring, read 1–2 existing pages on the site via `get_page` to inherit the voice. Pages on the same site should share tone, sentence rhythm, and CTA verb style. If the existing site uses terse declarative copy ("Ship 10x faster"), don't drift into verbose marketing prose; if the site is editorial, don't switch to terse.
