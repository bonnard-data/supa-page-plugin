# Full section reference

Every section type, every prop, every default. Use as a lookup when composing or auditing page JSON. The canonical names below are recommended; legacy aliases stay accepted.

## Universal props

| Prop | Type | Per-type default | Notes |
|---|---|---|---|
| `width` | `"prose" \| "default" \| "wide" \| "full"` | varies | Bounded enum; not pixels. |
| `background` | `"bg" \| "fg" \| "accent" \| "muted"` | varies | Semantic token. Maps to theme via section CSS vars. |

## `hero`

| Prop | Type | Default | Notes |
|---|---|---|---|
| `title` (alias `headline`) | string | `""` | Main headline. |
| `description` (alias `sub`) | string | `""` | One-line subhead under the title. |
| `eyebrow` | string | — | Small kicker above the title. |
| `badge` | `{ label, href? }` | — | Pill above the eyebrow (announcement, raise, "new in 2026"). |
| `cta` | `{ label, href }` | — | Primary CTA button. |
| `cta_secondary` | `{ label, href }` | — | Ghost button rendered next to the primary. |
| `align` | `"left" \| "center"` | `"center"` | Headline + description alignment. |

Defaults: `width: "wide"`, `background: "bg"`.

## `feature-grid`

| Prop | Type | Default | Notes |
|---|---|---|---|
| `eyebrow` | string | — | |
| `title` (alias `heading`) | string | — | |
| `description` | string | — | Supporting paragraph below the title. |
| `columns` | `2 \| 3 \| 4` | `3` | Other values clamp to 3. |
| `items[]` | `{ title, description?, body?, icon?, cta? }[]` | required | `description` is canonical; `body` is the legacy alias. `cta`: `{ label, href }` for per-card "Learn more →". |

Defaults: `width: "wide"`, `background: "bg"`.

## `cta`

| Prop | Type | Default | Notes |
|---|---|---|---|
| `eyebrow` | string | — | |
| `title` (alias `headline`) | string | `""` | |
| `description` (alias `sub`) | string | `""` | |
| `cta` (alias `button`) | `{ label, href }` | — | Primary action. |
| `cta_secondary` | `{ label, href }` | — | Ghost button. |

Defaults: `width: "wide"`, `background: "accent"`.

## `quote`

| Prop | Type | Default | Notes |
|---|---|---|---|
| `quote` | string | required | The testimonial text. |
| `author` (alias `name`) | string | — | |
| `role` | string | — | Job title only. |
| `company` | string | — | Company name. Renders as "Role, Company" together. |
| `byline` | string | — | Legacy alias when role + company aren't split. |
| `avatar` | string (URL) | — | Person photo. |
| `logo` | string (URL) | — | Company logo. |
| `rating` | `1\|2\|3\|4\|5` | — | Renders stars. |
| `href` | string | — | Optional "Read case study →" link. |

Defaults: `width: "prose"`, `background: "muted"`.

## `testimonials`

| Prop | Type | Default | Notes |
|---|---|---|---|
| `title` (alias `heading`) | string | — | |
| `description` | string | — | |
| `layout` | `"grid" \| "carousel"` | `"grid"` | Carousel is CSS-only (scroll-snap), no JS. |
| `items[]` | `{ quote, author?, role?, company?, avatar?, logo?, rating?, href? }[]` | required | Same item shape as `quote`. |

Defaults: `width: "wide"`, `background: "bg"`.

## `faq`

| Prop | Type | Default | Notes |
|---|---|---|---|
| `title` (alias `heading`) | string | — | |
| `description` | string | — | |
| `behavior` | `"single" \| "multiple" \| "open"` | `"single"` | `"single"` = native `<details name="faq">`; only one open at a time. `"open"` = all expanded (best for SEO crawlability). |
| `items[]` | `{ question, answer, id? }[]` (aliases `q` / `a`) | required | `id` auto-slugifies from `question` if absent — used for #anchor links. |

**JSON-LD:** every FAQ section auto-emits `<script type="application/ld+json">` with the schema.org FAQPage shape. AI-search surfaces (Perplexity, ChatGPT, Google AI Overviews) parse this even though Google killed FAQ rich results on 2026-05-07.

Defaults: `width: "default"`, `background: "bg"`.

## `text`

| Prop | Type | Default | Notes |
|---|---|---|---|
| `eyebrow` | string | — | |
| `title` (alias `heading`) | string | — | |
| `heading_level` | `2 \| 3` | `2` | Render as `<h2>` or `<h3>`. |
| `body` | string (Markdown) | — | Canonical path. Rendered with `marked` (same as posts). |
| `paragraphs[]` | string[] | — | Legacy: flat plain-text paragraphs. Ignored when `body` is set. |

Defaults: `width: "prose"`, `background: "bg"`.

## `post-feed`

| Prop | Type | Default | Notes |
|---|---|---|---|
| `title` (alias `heading`) | string | — | |
| `tag` | string | — | Filter to posts with this tag in frontmatter. |
| `sort` | `"newest" \| "oldest"` | `"newest"` | |
| `limit` | number | `10` | |
| `show_excerpt` | boolean | `true` | When `false`, render just title + date. |
| `featured` | boolean | `false` | When `true`, only show posts whose frontmatter has `featured: true`. |

Posts are read from the `posts` table for the site. See the `posts-and-blog` skill for frontmatter rules.

Defaults: `width: "default"`, `background: "bg"`.

## `pricing`

| Prop | Type | Default | Notes |
|---|---|---|---|
| `eyebrow` | string | — | |
| `title` (alias `heading`) | string | — | |
| `billing_note` | string | — | E.g. "Per seat, billed monthly. Cancel anytime." |
| `tiers[]` | see below | required | |

Tier shape:

| Prop | Type | Notes |
|---|---|---|
| `name` | string | "Starter" / "Pro" / etc. |
| `price` | string | Pre-formatted display: `"$0"`, `"€19"`, `"Free"`, `"Custom"`. |
| `price_suffix` | string | `"/mo"`, `"/seat"`, `"per user"`. |
| `description` | string | One-line tier description. |
| `features` | string[] | Bullet list, ✓-prefixed. |
| `cta_label`, `cta_href` | string | Per-tier CTA. |
| `featured` | boolean | Highlight with accent ring + "Most popular" badge. |

Defaults: `width: "wide"`, `background: "bg"`.

## `logos`

| Prop | Type | Default | Notes |
|---|---|---|---|
| `heading` | string | — | Small label above the cloud. |
| `layout` | `"grid" \| "marquee"` | `"grid"` | Marquee is CSS animation, respects `prefers-reduced-motion`. |
| `monochrome` | boolean | `true` | Grayscale + opacity, with full-color hover. |
| `items[]` | `{ src, name }[]` | required | `name` is the alt text. |

Defaults: `width: "wide"`, `background: "muted"`.

## `announcement-bar`

| Prop | Type | Default | Notes |
|---|---|---|---|
| `message` | string | required | |
| `cta` | `{ label, href }` | — | Inline link after the message. |
| `dismissible` | boolean | `false` | Adds a `×` close button. |

Place first in `sections[]` to render above the hero. Defaults: `width: "full"`, `background: "accent"`.

## `stats`

| Prop | Type | Default | Notes |
|---|---|---|---|
| `eyebrow` | string | — | |
| `title` (alias `heading`) | string | — | |
| `items[]` | `{ value, label, description? }[]` | required | `value` is a pre-formatted display string (`"10M+"`, `"99.99%"`). |

Defaults: `width: "wide"`, `background: "bg"`.

## `steps`

| Prop | Type | Default | Notes |
|---|---|---|---|
| `eyebrow` | string | — | |
| `title` (alias `heading`) | string | — | |
| `description` | string | — | |
| `items[]` | `{ title, description?, icon? }[]` | required | Auto-numbered (1, 2, 3) unless an item ships its own `icon`. |

Defaults: `width: "wide"`, `background: "bg"`.

## `team`

| Prop | Type | Default | Notes |
|---|---|---|---|
| `eyebrow` | string | — | |
| `title` (alias `heading`) | string | — | |
| `description` | string | — | |
| `items[]` | `{ name, role?, photo?, bio?, links? }[]` | required | `links: [{ label?, kind?, href }]` — small inline list under the bio. |

Defaults: `width: "wide"`, `background: "bg"`.

## `raw-embed`

Last resort. Customer-authored HTML + scoped CSS, rendered inside a shadow DOM so styles don't leak.

| Prop | Type | Default | Notes |
|---|---|---|---|
| `html` | string | required | Verbatim HTML. |
| `css` | string | — | Scoped to the shadow root — class names can't collide with the rest of the page. |
| `name` | string | — | Debug label for SEO lint + transcripts. |

The SEO lint warns when a `raw-embed` has substantial text without semantic tags, or when it contains `<iframe>` without a `title=` attribute.

Defaults: `width: "wide"`, `background: "bg"`.

## Per-type defaults at a glance

```
hero               wide    bg
feature-grid       wide    bg
cta                wide    accent
quote              prose   muted
testimonials       wide    bg
faq                default bg
text               prose   bg
post-feed          default bg
pricing            wide    bg
logos              wide    muted
announcement-bar   full    accent
stats              wide    bg
steps              wide    bg
team               wide    bg
raw-embed          wide    bg
```
