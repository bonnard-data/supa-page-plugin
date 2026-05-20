# Frontmatter reference

Every field a supa.page post can carry, with edge cases.

## Layout

YAML frontmatter at the very top of the file, between `---` markers. No
blank lines before the opening `---`. Body comes after the closing `---`.

```markdown
---
title: ...
date: ...
published: true
---

Body in Markdown.
```

## Fields

### `title` (string)

The post title. Renders as `<h1>` on the post page + `<title>` in `<head>`
+ `<title>` in RSS items + the link text in `post-feed` listings.

If absent or empty, the slug (filename without `.md`) is used as the
title. This is intentional — broken-frontmatter posts still render at
something. But always set `title` explicitly.

### `date` (string or YAML date)

ISO 8601 date string (`2026-05-20`) or a YAML date literal (`2026-05-20`).
The parser:

- Strings: passed through verbatim.
- YAML dates: converted to `Date.toISOString()`.
- Anything else: empty string. The post sorts last in feeds; no date line
  renders.

### `published` (boolean)

**The draft gate.** `true` makes the post appear in `/posts`, RSS, sitemap,
and any `post-feed`. Any other value (`false`, missing, string `"true"`,
number `1`, etc.) treats the post as a draft.

Strict equality: only `true` (YAML boolean true) gates the post live. This
is deliberately strict so a typo in frontmatter doesn't accidentally
publish a half-written post.

### `excerpt` (string)

Short summary. Used for:
- `post-feed` item excerpt
- RSS `<description>`
- OG `description` on the post page (falls back to site description if
  empty)
- Twitter card description

Keep it under ~160 chars for clean OG / Twitter rendering.

### `tags` (string[])

Array of tag strings. Filter for `post-feed.tag` matches the array
membership exactly (case-sensitive). Non-string entries are silently
dropped.

```yaml
tags: [engineering, retros]
tags: [Engineering, "open-source"]
```

### `featured` (boolean)

When `true`, the post matches `post-feed.featured: true` filters. Otherwise
behaves like any published post.

### `og_image` (string)

Path or URL of the OG card image. Pre-v0.2 this must be a public URL —
the sync hook doesn't ship binary assets reliably.

```yaml
og_image: https://cdn.example.com/og/post.png
og_image: /og/post.png   # only works if you have a separate way to host this
```

### `slug` (ignored)

Filename is the slug. A `slug:` field in frontmatter is silently ignored —
this exists so the URL and the on-disk filename can never drift apart.

## Edge cases

### Body starts with `# Title`

Don't do this. The platform already renders `<h1>{title}</h1>` from
frontmatter. Starting the body with `# Title` produces two titles.

Start body subsections at `##`.

### Date in the future

Future-dated posts are NOT scheduled-publish. They render whenever
`published: true` is set, regardless of date. The date is used only for
display + sort.

If you want scheduled publish, set `published: false` and flip it on
manually when the date arrives. Native scheduling is a future feature.

### Multiple posts with same date

Sort stability: ties broken by slug alphabetically (because the underlying
read returns files in directory order, then we sort by date desc).

### Empty body

A post with frontmatter but no body renders the title + date + an empty
`<div class="post-content">`. Valid but ugly.

### Body is not Markdown but HTML

Markdown allows inline HTML, so this works:

```markdown
---
title: ...
published: true
---

<div class="custom">
  <p>HTML inside Markdown</p>
</div>
```

But:
- The secret-scan hook still fires on the content.
- The renderer doesn't sanitise — be careful with `<script>` tags.
- Better to use Markdown when possible; reserve HTML for things Markdown
  can't express.
