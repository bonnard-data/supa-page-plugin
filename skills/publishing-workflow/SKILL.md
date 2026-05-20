---
name: publishing-workflow
description: This skill should be used when the user asks how supa.page hosting works under the hood, when they hit publish / draft / preview issues, when they say "what's the difference between preview and prod", "my edit didn't go live", "publish drafts", "throw away my drafts", "what does /publish actually do", "where does my content live", or when troubleshooting why a change isn't visible on the production URL.
version: 0.4.0
---

# How supa.page publishes content (v0.4.0)

A correct mental model for what `/edit-page`, `/edit-post`, `/update-theme`, `/diff`, `/publish`, `/discard-changes`, and the production / preview URLs all do — and why.

## The model: drafts + main, backed by SQLite

The source of truth is the platform's SQLite database. Every content type has two tables:

| Type | Live (main) | Draft (staging) |
|---|---|---|
| Pages | `pages` | `pages_draft` |
| Posts | `posts` | `posts_draft` |
| Site config | `site_config` | `site_config_draft` |

Edits (`upsert_page`, `upsert_post`, `update_site_config`, `delete_page`, `delete_post`) write to the `_draft` tables. `publish_site` promotes drafts → main and re-renders the static HTML served by Caddy. **The live URL updates immediately on publish.**

There is **no snapshot history and no rollback** in v0.4.0. If a publish was a mistake, edit forward and publish again.

## The two channels

| Channel | URL pattern | Reads from |
|---|---|---|
| **Preview** | `<site>.supa.page/?preview=1` | `*_draft` tables (latest edits) |
| **Production** | `<site>.supa.page` (or custom domain) | main tables + pre-rendered static HTML |

Preview shows whatever you've upserted into drafts. Production shows the last publish. Different rows of the same database tables.

The preview channel also opens an **SSE stream** — when a draft row changes, any open preview tab reloads automatically. Useful when you're iterating with the agent.

## The commands and what they actually do

### `/edit-page`, `/edit-post`, `/update-theme`, `/delete-page`, `/delete-post`

Each routes to the matching MCP tool. All writes land in the `_draft` table for that content type. The full object is replaced on every call — there's no field-level patch (except `update_site_config`, which has top-level merge semantics).

- Reflected in **preview immediately**.
- **Not visible on production** until you `/publish`.

Validation runs at upsert time — a malformed page object or post body rejects the whole call with `{error, field}`. The draft tables stay untouched on failure.

### `/diff`

Calls `diff_site` — compares the `_draft` tables against main. Returns:

```ts
{
  pages: { added: string[], modified: string[], deleted: string[] },
  posts: { added: string[], modified: string[], deleted: string[] },
  site_config: "unchanged" | "modified"
}
```

Use before `/publish` to confirm what's about to go live.

### `/publish [message]`

Calls `publish_site`. In one transaction the server:

1. Copies every row from `pages_draft` → `pages`, `posts_draft` → `posts`, `site_config_draft` → `site_config`.
2. Applies any pending deletions (rows present in main but missing from drafts).
3. Records the publish in the `publishes` log table (so we have an audit trail — but no per-publish snapshot to roll back to).
4. Re-renders the static HTML and writes it to the Caddy-served directory atomically (temp dir + rename).

**Atomic.** The renderer never serves half a publish.

### `/discard-changes [scope] [slug]`

Calls `discard_changes`. Truncates the `_draft` row(s) for the chosen scope:

- `{site}` — all drafts (pages + posts + site_config)
- `{site, kind: "page", slug}` — one page draft
- `{site, kind: "post", slug}` — one post draft
- `{site, kind: "site_config"}` — site_config draft

Live main is untouched.

### `/visibility public|private`

Controls who can view `<site>.supa.page`. Independent of `/publish` — toggling visibility doesn't re-publish.

- `private` (default for new sites): non-org-members get redirected to `/signin`.
- `public`: anyone can view.

Preview (`?preview=1`) is **always reachable** if you know the URL — visibility only gates the production URL.

## The mental model

> **Drafts are your working tree. Main is your production tree. `/publish` is the only operation that moves bytes between them.**

git mapped onto two SQLite tables per content type:

| Git | supa.page |
|---|---|
| working tree | `_draft` tables |
| HEAD | main tables |
| `git status` | `/diff` |
| `git commit && deploy` | `/publish` |
| `git restore <file>` | `/discard-changes` |

There is no `git checkout <older commit>` — no snapshot history.

## Production routing

A request to `<name>.supa.page` flows:

1. Caddy receives the connection, terminates TLS via on-demand cert.
2. Caddy serves the pre-rendered static HTML for `/`, `/<page-slug>`, `/posts/`, `/posts/<slug>`, `/rss.xml`, `/sitemap.xml` directly from disk.
3. Anything not in the static tree falls through to the dynamic Hono renderer (404 + a few special-case routes).

The static HTML is regenerated on every `/publish`. There's no cache to invalidate — the bytes on disk are the source.

## Preview routing

A request to `<name>.supa.page/?preview=1` flows:

1. Caddy proxies the request to the dynamic Hono renderer (the static layer ignores `?preview=1`).
2. The renderer reads from the `_draft` tables.
3. Sends back the rendered HTML + opens an SSE channel for live reload.

Preview bypasses visibility. The URL is unguessable enough for an alpha; an explicit preview-token mechanism is on the roadmap.

## Common failure modes

### "My edit isn't on the live URL"

Either:
- You didn't `/publish` after the edit — check `/diff` to confirm.
- `visibility = private` and you're not signed in — `/visibility public` or sign in.
- (For posts) the post has `published: false` — flip it and re-publish.

### "I edited a post but it's not showing up in preview either"

Posts have a per-row `published` boolean in addition to the draft/main gate. A post with `published: false` is invisible in both channels for `/posts`, RSS, sitemap, and `post-feed` — though its direct URL `/posts/<slug>` is reachable via `?preview=1`.

### "I want to undo the last publish"

You can't roll back in v0.4.0. Edit forward — change the drafts to the previous content and `/publish` again. If you don't remember the previous content and need it, the dashboard surfaces the publish log; for full snapshot history, that's the v0.5 roadmap.

### "Two `/publish`es in fast succession — which one wins?"

Whichever transaction committed second. SQLite serialises writes on a single writer; there's no interleaving.

## Anti-patterns

- **Editing pages by hand-writing JSON in a local file.** v0.4.0 has no file-based source tree. Use `/edit-page` or `upsert_page` directly.
- **Calling `/publish` from a loop.** Each publish triggers an HTML re-render. Cheap, but pointless to do per-keystroke.
- **Treating `/preview` as a separate publish.** Preview reads drafts. If you haven't upserted, preview is stale.
- **Expecting `/discard-changes` to roll back a publish.** It only resets drafts. Main is unaffected.

## Additional resources

- **`references/snapshot-internals.md`** — how publishes commit atomically + the static-HTML re-render pipeline.
- **`examples/typical-day.md`** — annotated walk-through of an edit-diff-publish session in v0.4.0.
