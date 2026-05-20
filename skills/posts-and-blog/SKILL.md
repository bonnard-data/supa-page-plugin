---
name: posts-and-blog
description: This skill should be used when authoring or editing blog posts on a supa.page site, or when the user asks to "write a blog post", "add a post", "draft a post", "publish a post", "set up RSS", "the post isn't showing up", "the post is a draft", "set featured: true", "tag a post", "schedule a post", or any task involving the supa.page Markdown post pipeline.
version: 0.4.0
---

# Blog posts on supa.page

Blog posts are SQLite rows in the `posts` (live) / `posts_draft` (staging) tables. You write them via `upsert_post({site, slug, post})`; the renderer reads them when assembling the blog index, RSS, sitemap, and `post-feed` sections. Posts render at `/posts/<slug>`. The slug is part of the row identity — change the slug = different post.

## Anatomy of a post

The post object passed to `upsert_post`:

```json
{
  "slug": "how-we-shipped-v0-1-3",
  "title": "How we shipped v0.1.3 in three weeks",
  "date": "2026-05-20",
  "published": true,
  "excerpt": "A retro on the supa.page hard-cut release.",
  "tags": ["engineering", "retros"],
  "featured": false,
  "og_image": "/og/v0.1.3.png",
  "body": "# Intro\n\nBody text in **Markdown**. The same `marked` pipeline the `text` section uses.\n\n## A subsection\n\n- list items\n- code: `inline`\n- [links](/other-page)\n\n```\ncode blocks work fine\n```\n\n> blockquotes\n"
}
```

The keys mirror the frontmatter shape from earlier file-based versions; v0.4.0 stores them as typed columns + a `body` Markdown column. There's no YAML to parse — the typed object is the wire format.

## Fields

| Field | Required | Default | Notes |
|---|---|---|---|
| `slug` | yes | — | The URL: `/posts/<slug>`. Must match `[a-z0-9-]`. |
| `title` | yes | slug | The post title. |
| `date` | yes-ish | empty | ISO date or `YYYY-MM-DD`. Used for sort order + display. Without it, the post sorts last and renders no date line. |
| `published` | **YES on prod** | `false` | **A post without `published: true` is a draft.** Drafts render only via `?preview=1` and are excluded from `/posts`, RSS, sitemap, and `post-feed`. |
| `excerpt` | no | `""` | Short summary for listings, RSS `<description>`, and OG `description`. |
| `tags` | no | `[]` | Array of strings. Used by `post-feed.tag` filter. |
| `featured` | no | `false` | When `true`, the post shows in feeds with `featured: true` filter. |
| `og_image` | no | none | Path or URL of the OG card image. Pre-v0.5 must be a public URL. |
| `body` | no | `""` | Markdown body. Rendered with `marked` + GFM. |

## The two-gate visibility model

Posts have **two independent gates**. Both must be open for a post to appear on production:

1. **Row-level `published: true`.** Per-post draft flag in the row itself.
2. **`/publish` promotes the row from `posts_draft` to `posts`.** Even `published: true` rows in `posts_draft` are not on prod until `/publish`.

Most "my post isn't showing up" cases are gate #1 (forgot to set `published: true`).

## Markdown rules

The renderer uses `marked` with GFM enabled, `breaks: false`. Concretely:

- **Headings** (`#`, `##`, `###`) — `<h1>` becomes a sub-heading inside the post; the post title is already rendered separately by the platform. Start sub-sections at `##`.
- **Hard line breaks** require a trailing `\\` on the prior line (GFM convention).
- **GFM tables** work.
- **Fenced code blocks** with language hint render with the right `<code class="language-x">` for syntax-highlighting if you load a highlighter.
- **HTML embedded in Markdown** works but isn't sanitised — be careful with `<script>` tags. Use the secret-scan hook to guard against credential paste.
- **Relative links** (`[other](/some-page)`) resolve to the site root.
- **Images:** `![alt](path)` — until native asset hosting ships, use a public URL (Cloudinary, ImageKit, your own CDN).

## Drafts workflow

```json
{
  "slug": "wip",
  "title": "Work in progress",
  "published": false,
  "date": "2026-05-21",
  "body": "Body text. Visible at /posts/wip via ?preview=1 only."
}
```

Flip `published: true` when ready, then `/publish` to ship.

## Listing posts on a page

Add a `post-feed` section. See the `section-catalogue` skill for the full prop list. Common shapes:

```json
{ "type": "post-feed", "title": "Blog" }
```

```json
{ "type": "post-feed", "tag": "engineering", "sort": "oldest", "limit": 20 }
```

```json
{ "type": "post-feed", "featured": true, "limit": 3, "show_excerpt": false }
```

## RSS + sitemap

The platform auto-generates `/rss.xml` and `/sitemap.xml` for every site. Posts that satisfy `published: true` AND have a `date` appear in RSS, sorted newest-first. The sitemap lists every published post plus every page slug.

You don't author these files. If a post isn't showing up in RSS, check `published` + `date`.

## OG images

Until native OG card generation ships, the post must point at a public image URL:

```json
{ "og_image": "https://cdn.example.com/og/my-post.png" }
```

The image renders in `<meta property="og:image">` and `<meta name="twitter:image">`. Twitter card type is `summary_large_image` when an OG image is present, `summary` otherwise.

## Slug rules

- Allowed characters: `[a-z0-9-]`. The validator below enforces this.
- The slug IS the URL — `/posts/<slug>`.
- To rename a post's URL, delete the old slug + upsert the new one. There's no rename operation.

## Pre-flight validation

```bash
node ${CLAUDE_PLUGIN_ROOT}/skills/posts-and-blog/scripts/validate-frontmatter.js path/to/post.json
```

(Pass a JSON file containing the post object — slug, title, date, published, etc. The validator checks: required fields, slug format, draft status, date parseability, tags shape.)

## Anti-patterns

- **Don't author posts as page objects.** Pages and posts are different tables with different shapes. The `text` section is for prose on a regular page — different rendering pipeline, different rules.
- **Don't put title in the Markdown body.** The platform renders `# {title}` from the typed column. Starting the body with `# Title` produces two titles.
- **Don't push secrets into the post body** — the `secret-scan` hook will refuse the write. Use the env / dashboard for real keys.
- **Don't add `feed-only: true`-style flags hoping to hide a post from the index.** The mechanism is `published: false` (draft) or `featured: true` on others.

## Additional resources

- **`references/frontmatter-reference.md`** — every field, every edge case.
- **`references/markdown-gotchas.md`** — the 6 most common Markdown pitfalls on supa.page.
- **`examples/`** — sample post objects: a draft, a published post, a featured post.
- **`scripts/validate-frontmatter.js`** — pre-flight validator.
