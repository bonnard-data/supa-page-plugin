# Post object reference

Every field a supa.page post can carry, with edge cases. The post is a typed object passed to `upsert_post`; v0.4.0 stores each field as a typed column (`body` is the only free-form Markdown).

## Shape

```json
{
  "slug": "...",
  "title": "...",
  "date": "...",
  "published": true,
  "excerpt": "...",
  "tags": [...],
  "featured": false,
  "og_image": "...",
  "body": "..."
}
```

## Fields

### `slug` (string, required)

The URL: `/posts/<slug>`. Must match `[a-z0-9-]`. Slug IS the row identity — to rename a post's URL, delete the old slug and upsert the new one.

### `title` (string)

The post title. Renders as `<h1>` on the post page + `<title>` in `<head>` + `<title>` in RSS items + the link text in `post-feed` listings.

If absent or empty, the slug is used as the title. This is intentional — broken-object posts still render at something. But always set `title` explicitly.

### `date` (string)

ISO 8601 date string (`2026-05-20`) or any string `new Date(...)` accepts. The parser:

- Valid date string: passed through verbatim.
- Empty / missing: the post sorts last in feeds; no date line renders.
- Unparseable garbage: same as missing.

### `published` (boolean)

**The draft gate.** `true` makes the post appear in `/posts`, RSS, sitemap, and any `post-feed`. Any other value (`false`, missing, string `"true"`, number `1`, etc.) treats the post as a draft.

Strict equality: only the JSON boolean `true` gates the post live. This is deliberately strict so a typo doesn't accidentally publish a half-written post.

This is independent of the **drafts/main** gate — even `published: true` rows in `posts_draft` aren't on production until `/publish`.

### `excerpt` (string)

Short summary. Used for:
- `post-feed` item excerpt
- RSS `<description>`
- OG `description` on the post page (falls back to site description if empty)
- Twitter card description

Keep it under ~160 chars for clean OG / Twitter rendering.

### `tags` (string[])

Array of tag strings. Filter for `post-feed.tag` matches the array membership exactly (case-sensitive). Non-string entries are silently dropped.

```json
{ "tags": ["engineering", "retros"] }
{ "tags": ["Engineering", "open-source"] }
```

### `featured` (boolean)

When `true`, the post matches `post-feed.featured: true` filters. Otherwise behaves like any published post.

### `og_image` (string)

Path or URL of the OG card image. Until native asset hosting ships, this must be a public URL.

```json
{ "og_image": "https://cdn.example.com/og/post.png" }
{ "og_image": "/og/post.png" }
```

### `body` (string)

Markdown post body. Rendered with `marked` + GFM. The body column has no length limit imposed by the schema, but very large posts (>500KB) start to feel slow in the renderer.

## Edge cases

### Body starts with `# Title`

Don't do this. The platform already renders `<h1>{title}</h1>` from the typed column. Starting the body with `# Title` produces two titles.

Start body subsections at `##`.

### Date in the future

Future-dated posts are NOT scheduled-publish. They render whenever `published: true` is set, regardless of date. The date is used only for display + sort.

If you want scheduled publish, set `published: false` and flip it on manually when the date arrives. Native scheduling is a future feature.

### Multiple posts with same date

Sort stability: ties broken by slug alphabetically.

### Empty body

A post with everything but an empty `body` renders the title + date + an empty `<div class="post-content">`. Valid but ugly.

### Body is not Markdown but HTML

Markdown allows inline HTML, so this works:

```json
{
  "body": "<div class=\"custom\">\n  <p>HTML inside Markdown</p>\n</div>"
}
```

But:
- The secret-scan hook still fires on the content.
- The renderer doesn't sanitise — be careful with `<script>` tags.
- Better to use Markdown when possible; reserve HTML for things Markdown can't express.
