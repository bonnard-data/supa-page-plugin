# Why the override surface is 8 tokens, not 80

A short rationale so future contributors don't quietly expand the allow-list and regret it.

## The thing we're guarding against

Customer themes that drift further from the platform's design system every quarter. The two patterns that produce this:

1. **A free-form `custom_css` escape hatch.** Once shipped, every awkward layout problem becomes "just add some custom CSS" — and the renderer's invariants (consistent typographic rhythm, semantic backgrounds, bounded width enums) erode one stylesheet at a time. Webflow + Squarespace customer-site quality across the long tail is the cautionary case.
2. **An override surface that exposes implementation tokens.** When `--bg`, `--leading`, `--tracking-tight`, `--bg-alt` are all overridable, every customer thinks they have to set them — and most pick values that break contrast or vertical rhythm.

The locked rule from the platform's design principles: **semantic tokens beat literal tokens, and small enumerated scales beat freeform inputs.** The 8-token allow-list is the concrete expression of that rule.

## Why these 8

| Token | Reason it's overridable |
|---|---|
| `--accent` | 70%+ of customer asks. Single highest-leverage knob. |
| `--accent-fg` | Required when accent is light (yellow brand, etc.) and default white-on-accent doesn't work. |
| `--radius` | Cheap aesthetic dial — sharp vs. soft is a brand decision, not a design-drift risk. |
| `--font-sans` | Brand body face. |
| `--font-serif` | Brand display face for the rare site that wants role-by-family typography. |
| `--font-mono` | Code samples; the safest font override possible. |
| `--border` | Card / divider color. Bounded by surface design. |
| `--width-prose` | Article-body width — the only layout dimension customers genuinely want to tune. |

## Why NOT these

| Token | Reason it's NOT overridable |
|---|---|
| `--bg` | Pick the wrong value and the whole page goes unreadable. Use a different preset instead. |
| `--fg` | Same — bad customer values produce 1.5:1 contrast against the bg. |
| `--muted` | Used in dozens of components; mis-set values cascade everywhere. |
| `--leading` | Wrong leading breaks every paragraph in the site. The preset gets this right. |
| `--tracking-tight` | Same as leading — preset-managed for vertical rhythm. |
| `--width-default`, `--width-wide` | Section widths are an enum (prose/default/wide/full). Customers pick the enum, not the raw value. |
| `--max-width` | Page-level limit, baked into the preset. |
| `--bg-alt` | Used for muted sections; coupled to `--bg` for contrast. |

If a customer ever has a legitimate need for one of these (e.g. dark mode), the **right** answer is a new preset, not exposing the raw token.

## When this list should grow

Three test questions:

1. **Is it a frequent ask?** (Logs / customer interviews should show 5+ asks before adding.)
2. **Does it have a single right value range?** (`--radius: 0` to `1rem` — yes. `--bg: any hex` — no.)
3. **Does the wrong value produce a graceful failure?** (Bad accent → ugly button. Bad bg → unreadable site.)

If all three are yes, add it. If any is no, the right answer is a new preset, a new component prop, or staying out of it.

## When the customer needs something this doesn't cover

The customization ladder:

- One-off styling on one section → `raw-embed` (shadow-DOM scoped).
- Site-wide visual change that goes beyond the 8 tokens → request a new preset (or `/add` a forked component — see `custom-components` skill).
- Specific component needs a new prop → file an issue. The platform adds props deliberately; customer JSON should never be the place where new design surface lands.
