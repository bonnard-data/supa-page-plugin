# Preset comparison

Side-by-side of the two v0.1.3 presets so you can pick the right starting point before reaching for overrides.

## At a glance

|   | `default` | `editorial` |
|---|---|---|
| **Body face** | Inter (system) | Spectral (Google) |
| **Heading face** | Inter (system) | Spectral |
| **Mono face** | system | JetBrains Mono |
| **Accent** | `#18181b` (near-black) | `#c44536` (crimson) |
| **Accent fg** | `#ffffff` | `#fafaf7` |
| **Background** | `#ffffff` | `#fafaf7` (warm cream) |
| **Foreground** | `#18181b` | `#1a1a1a` |
| **Muted text** | `#52525b` | `#4a4742` |
| **Border** | `#e4e4e7` | `#e8e4dc` |
| **Radius** | `0.5rem` | `0.25rem` (sharper) |
| **Leading** | `1.55` | `1.65` (more open) |
| **Width-prose** | `36rem` | `34rem` (slightly narrower) |
| **External font load** | none | Google Fonts preload |
| **Feels like** | Linear / Stripe / Vercel marketing | Vox / Stratechery / The Atlantic |

## When to pick `default`

- B2B SaaS, dev tools, infrastructure products
- Pages that are mostly hero + features + pricing
- You want fast first paint (no font load)
- You'll override `--accent` to your brand color

## When to pick `editorial`

- Personal blogs, magazines, newsletters
- Long-form essays where reading flow matters
- You're OK with a single external font request (preloads + `display: optional`)
- You want a "designed" look without authoring CSS

## When neither fits

If both presets are wrong for the brand, the right move is:

1. Start from `default`.
2. Set overrides for `--accent`, `--accent-fg`, `--radius`, `--font-sans`.
3. If you still need more, file a request for a new preset rather than fighting the design system one override at a time.

## Combining presets + overrides

You can override **any** of the 8 allow-listed tokens regardless of which preset you start from. Common combinations:

### Editorial-with-purple-brand

```json
{
  "theme": "editorial",
  "theme_overrides": {
    "--accent": "oklch(0.55 0.25 280)",
    "--accent-fg": "#ffffff"
  }
}
```

Keeps the Spectral typography + cream background, swaps the crimson accent for purple.

### Default-with-rounder-look

```json
{
  "theme": "default",
  "theme_overrides": {
    "--radius": "0.875rem"
  }
}
```

System Inter + softer pill-like buttons + cards.

### Default-with-tighter-prose

```json
{
  "theme": "default",
  "theme_overrides": {
    "--width-prose": "32rem"
  }
}
```

For prose-heavy sites that want tighter columns without switching to editorial.
