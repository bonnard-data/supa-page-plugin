---
name: posts-and-blog
description: This skill should be used when authoring or editing blog posts under `source/posts/*.md`, or when the user asks to "write a blog post", "add a post", "draft a post", "publish a post", "set up RSS", "the post isn't showing up", "the post is a draft", "set featured: true", "tag a post", "schedule a post", or any task involving the supa.page Markdown post pipeline.
version: 0.1.3
---

# Blog posts on supa.page

Blog posts live in `<site-dir>/source/posts/<slug>.md`. They render at `/posts/<slug>` and appear in `post-feed` sections + RSS + sitemap. The slug comes from the filename — frontmatter `slug` is ignored on purpose so the URL and filename can never drift apart.

## Anatomy of a post

```markdown
---
title: "How we shipped v0.1.3 in three weeks"
date: 2026-05-20
published: true
excerpt: "A retro on the supa.page hard-cut release."
tags: [engineering, retros]
featured: false
og_image: /og/v0.1.3.png
---

# Intro

Body text in **Markdown**. The same `marked` pipeline the `text` section uses.

## A subsection

- list items
- code: `inline`
- [links](/other-page)

```code blocks
work fine
```

> blockquotes
```

## Frontmatter fields

| Field | Required | Default | Notes |
|---|---|---|---|
| `title` | yes | filename | The post title. |
| `date` | yes-ish | empty | ISO date or `YYYY-MM-DD`. Used for sort order + display. Without it, the post sorts last and renders no date line. |
| `published` | **YES on prod** | `false` | **A post without `published: true` is a draft.** Drafts render only via `?preview=<site>` and are excluded from `/posts`, RSS, sitemap, and `post-feed`. |
| `excerpt` | no | `""` | Short summary for listings, RSS `<description>`, and OG `description`. |
| `tags` | no | `[]` | Array of strings. Used by `post-feed.tag` filter. |
| `featured` | no | `false` | When `true`, the post shows in feeds with `featured: true` filter. |
| `og_image` | no | none | Path or URL of the OG card image. Pre-v0.2 must be a public URL. |

## The draft gate

This is the most-bitten footgun. **The default for `published` is `false`.** A post you forget to mark `published: true` will:

- Not appear in `/posts` index
- Not appear in RSS
- Not appear in sitemap
- Not match any `post-feed` section in production
- Still render at its direct URL only via `?preview=<site>` (preview channel)

If a customer says "my post isn't showing up", check the frontmatter first.

The reason it works this way: post-level draft state is the **only** content state that lives outside the publish boundary. The rest of the site has one publish flag (`/publish`). Posts let you author drafts in `source/` and only flip them live with the frontmatter.

## Markdown rules

The renderer uses `marked` with GFM enabled, `breaks: false`. Concretely:

- **Headings** (`#`, `##`, `###`) — `<h1>` becomes a sub-heading inside the post; the post title is already rendered separately by the platform. Start sub-sections at `##`.
- **Hard line breaks** require a trailing `\\` on the prior line (GFM convention).
- **GFM tables** work.
- **Fenced code blocks** with language hint render with the right `<code class="language-x">` for syntax-highlighting if you load a highlighter.
- **HTML embedded in Markdown** works but isn't sanitised — be careful with `<script>` tags. Use the secret-scan hook to guard against credential paste.
- **Relative links** (`[other](/some-page)`) resolve to the site root.
- **Images:** `![alt](path)` — until native asset hosting ships in v0.2, use a public URL (Cloudinary, ImageKit, your own CDN). The sync hook can't ship binary files reliably.

## Drafts workflow

```markdown
---
title: Work in progress
published: false   # explicit; the default
date: 2026-05-21
---

Body text. Visible at /posts/<slug> via ?preview=<site> only.
```

Flip to `published: true` when ready, run `/publish`, and the post appears in `/posts` + RSS + sitemap.

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

The platform auto-generates `/rss.xml` and `/sitemap.xml` for every site. Posts that satisfy `published: true` AND have a `date` appear in RSS, sorted newest-first. The sitemap lists every published post plus every `pages/*.json` route.

You don't author these files. If a post isn't showing up in RSS, check `published` + `date`.

## OG images

Until v0.2 ships native OG card generation, the post must point at a public image URL:

```yaml
og_image: https://cdn.example.com/og/my-post.png
```

The image renders in `<meta property="og:image">` and `<meta name="twitter:image">`. Twitter card type is `summary_large_image` when an OG image is present, `summary` otherwise.

## Slug rules

- Filename = slug. `2026-05-20-launch.md` → `/posts/2026-05-20-launch`.
- Allowed: `[a-z0-9-]`. The validator below enforces this.
- The `slug` frontmatter field is ignored — change the filename to change the URL.
- Don't include `.md` in the slug.

## Pre-flight validation

```bash
node ${CLAUDE_PLUGIN_ROOT}/skills/posts-and-blog/scripts/validate-frontmatter.js path/to/post.md
```

Checks: required fields, slug format, draft status, date parseability, tags shape.

## Anti-patterns

- **Don't author posts as page JSON.** Posts are Markdown with YAML frontmatter, in `source/posts/`. The `text` section is for prose blocks on a regular page — different rendering pipeline, different rules.
- **Don't put title in the Markdown body.** The platform renders `# {title}` from the frontmatter. Starting the body with `# Title` produces two titles.
- **Don't use `slug:` in frontmatter** thinking it changes the URL. It doesn't. Rename the file.
- **Don't push secrets into the post body** — the `secret-scan` hook will refuse the write. Use the env / dashboard for real keys.
- **Don't add `feed-only: true`-style flags hoping to hide a post from the index.** The mechanism is `published: false` (draft) or `featured: true` on others.

## Additional resources

- **`references/frontmatter-reference.md`** — every field, every edge case.
- **`references/markdown-gotchas.md`** — the 6 most common Markdown pitfalls on supa.page.
- **`examples/`** — a draft post, a published post, a featured post, a tagged post.
- **`scripts/validate-frontmatter.js`** — pre-flight validator.
