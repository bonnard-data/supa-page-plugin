# Publish atomicity + the static re-render pipeline

How `publish_site` commits in v0.4.0, and why production never sees a half-promoted state.

## The publish transaction

A `/publish` call wraps the whole promotion + re-render in one transaction. In rough order:

1. **Begin SQLite transaction.**
2. For each content type:
   - `INSERT OR REPLACE INTO pages SELECT * FROM pages_draft WHERE site_id = ?`
   - `INSERT OR REPLACE INTO posts SELECT * FROM posts_draft WHERE site_id = ?`
   - `INSERT OR REPLACE INTO site_config SELECT * FROM site_config_draft WHERE site_id = ?`
3. Apply pending deletions — rows present in main but absent from drafts. (Discoverable via a left-join against `*_draft`.)
4. Write a row to the `publishes` log table: `{ publish_id, site_id, message, promoted_at, summary }`.
5. **Commit SQLite transaction.**
6. Re-render the static HTML for every page + post + index + RSS + sitemap to a fresh temp directory.
7. `rename(<temp>, <live>)` — atomic on POSIX (same filesystem).

Steps 1–5 are atomic at the DB level. If 6 fails (disk full, render bug), the DB has already been promoted — production main is the new version, but Caddy is still serving the old static files. The next `publish_site` call will retry the re-render; in practice we also have a poller that re-renders on detection of stale static-mtime vs publish-time. Acceptable for indie scale.

## Why the renderer never sees a half-publish

The static directory is swapped atomically via `rename`. Caddy's file-serving handler resolves the directory path on each request; a request that arrives mid-`rename` either sees the old directory or the new one, never both.

The dynamic preview renderer reads from the `_draft` tables directly. It never sees the main tables mid-transaction because of SQLite's MVCC — readers see a consistent snapshot of committed rows.

## Per-site serialisation

A `Map<siteName, Promise>` chain in `publish.ts` serialises:

- `publish_site(site)` calls
- `discard_changes(site)` calls
- bulk imports for that site

Two simultaneous `/publish`es queue back-to-back, both succeed, second is the new main. Two `upsert_page`s in flight rely on SQLite's writer-serialisation — applied in order.

The mutex is per-site so unrelated sites don't block each other.

## What v0.4.0 does NOT do

- **No snapshot history.** Each `/publish` overwrites main. There is no rollback target.
- **No cross-site atomicity.** Site A and site B publish independently.
- **No cross-region replication.** Single Hetzner box; no DR replica.
- **No fsync durability guarantee.** A hard power loss within a few seconds of a publish can lose the publish (SQLite WAL helps but is best-effort). Litestream → R2 is on the roadmap.

## Diff implementation

`diff_site({site})` walks the `_draft` tables and joins against main:

```ts
{
  pages: { added: string[], modified: string[], deleted: string[] },
  posts: { added: string[], modified: string[], deleted: string[] },
  site_config: "unchanged" | "modified"
}
```

`modified` compares serialised JSON for pages/posts (`JSON_EXTRACT` + string compare). Tombstone rows in `_draft` (representing pending deletes) show up as `deleted`.

## The publish log

The `publishes` table stores `{ publish_id, site_id, message, promoted_at, summary }` for every publish. It exists for audit + the dashboard's history view — not for rollback. The `list_publishes` MCP tool was removed in v0.4.0; the dashboard remains the way to inspect history.
