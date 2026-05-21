# Composition patterns

Five proven page recipes built from the v0.1.3 catalogue. Copy + adapt rather than authoring from memory.

## 1. Indie SaaS landing page

The default starting point for a one-product page.

```
announcement-bar?     ← optional, for launches / raises
hero                  ← title + dual CTA + optional badge
logos                 ← "Trusted by"
feature-grid (3 col)  ← 3–6 capability tiles
quote                 ← single hero-quote testimonial
pricing               ← 2–3 tiers, one featured
faq                   ← 4–8 questions
cta                   ← final "Start free"
```

Why this order: hero → social proof (logos) → product (features) → trust (testimonial) → price → objection-handling (faq) → re-ask for the conversion.

## 2. Open-source / dev tool

Different rhythm — devs want to see code + integration before pricing.

```
hero (eyebrow="Open source")
feature-grid (4 col)  ← capabilities
steps                 ← "Three commands to install"
raw-embed             ← code snippet (terminal output / API call)
stats                 ← stars / downloads / contributors
testimonials (grid)   ← 3–6 community quotes
faq
cta                   ← "Read the docs" + "Star on GitHub"
```

## 3. B2B / sales-led

Heavier on logos and case studies; pricing usually deferred to "Talk to sales".

```
hero (align=left)     ← left-align reads more enterprise
logos                 ← Fortune 500 names
feature-grid (2 col)  ← bigger tiles for fewer, deeper capabilities
testimonials (grid)   ← 3 quotes with company logos
stats                 ← contract value / customer count / NPS
cta                   ← "Schedule a demo" (no self-serve)
```

Skip `pricing` entirely or put it on `/pricing` and link from the CTA.

## 4. Newsletter / writer landing

Minimal — get them to subscribe.

```
hero                  ← name + tagline + subscribe CTA
text                  ← Markdown body — about the writer + topic
post-feed             ← recent posts (limit: 5, show_excerpt: true)
raw-embed             ← convertkit / mailerlite form
cta                   ← subscribe again
```

## 5. About / Team page

Different from the landing — meta-narrative + people.

```
hero (align=left)     ← short manifesto
text                  ← Markdown longform (story, beliefs, principles)
team                  ← 3–9 people with photos
stats                 ← optional "founded 2024", "employees 4", "customers 200"
cta                   ← "Join us" → /careers
```

## Anti-recipes (don't do these)

### "Hero stuffing"

Putting eyebrow + badge + title + description + cta + cta_secondary + a hero image all crammed in. Pick the 3–4 elements that earn space. A single CTA outperforms two confused ones.

### "Hero + nothing else"

A title and a button. Visitors who don't convert from the hero have nowhere else to land. Add at least one `feature-grid` or `quote`.

### "Pricing first"

Pricing before features means the visitor has no idea what they're paying for. Pricing belongs after the value pitch.

### "Multiple quote sections"

If you have 3+ testimonials, use `testimonials` (plural). Three `quote` sections in a row reads like padding.

### "5 columns in feature-grid"

The schema clamps `columns` to `2|3|4`. 5 columns crushes feature density beyond readability; if you have 5 features either drop the weakest or use `columns: 3` + a second `feature-grid` below.

### "Custom CSS via raw-embed"

`raw-embed` is shadow-DOM scoped — it can't bleed into other sections, but it also can't restyle them. If you want to change the visual look globally, use `theme_overrides` in `site.json` (see the `theme-tokens` skill). Don't stack 14 `raw-embed` sections trying to recreate a custom design system.

## When to drop sections

A landing page does NOT need every section type. Cut what doesn't earn its place. The two sections that should appear in every B2C/B2B landing:

- **hero** — without it the visitor has no anchor
- **cta** at the end — the final ask

Everything else is optional and depends on the product's evidence pyramid (logos, testimonials, stats, pricing, features, etc.).
