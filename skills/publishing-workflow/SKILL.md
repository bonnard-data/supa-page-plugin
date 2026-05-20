---
name: publishing-workflow
description: This skill should be used when the user asks how supa.page hosting works under the hood, when they hit publish / rollback / sync issues, when they say "what's the difference between preview and prod", "my edit didn't go live", "roll back to yesterday's version", "publish staging", "what's a snapshot", "where do my files live", "what does /publish actually do", or when troubleshooting why a change isn't visible on the production URL.
version: 0.1.3
---

# How supa.page publishes content

A correct mental model for what `/sync`, `/publish`, `/rollback`, `/diff`, and the production / preview URLs all do — and why.

## The two channels

Every site has two channels:

| Channel | URL pattern | Reads from |
|---|---|---|
| **Preview** | `<server>/?preview=<site>` | `sites/<site>/source/` (latest edits) |
| **Production** | `<site>.supa.page` (or custom domain) | `sites/<site>/publishes/<current>/source/` (last `/publish`) |

Preview shows what you've staged locally + auto-synced. Production shows the last `/publish`. Two different file trees on the server.

## On-disk layout (server)

```
sites/<name>/
  source/                                 ← staging area; written by /sync
    site.json
    pages/index.json
    pages/about.json
    posts/*.md
    components/                           ← customer Lit (rare)
  publishes/
    .tmp-<id>/                            ← in-flight publish (renamed atomically)
    2026-05-20T15-30-00.000Z-abcd1234/
      source/                             ← immutable snapshot of source/
      meta.json                           ← { snapshot, timestamp, message }
    2026-05-19T20-00-00.000Z-deadbeef/
      source/
      meta.json
  current.json                            ← {"snapshot": "..."} — what prod reads
```

The renderer never serves the same bytes from `source/` and the live snapshot at the same time — `source/` is staging only.

## The commands and what they actually do

### `/sync` (PostToolUse hook, automatic)

Every Write/Edit/MultiEdit inside `<site-dir>/source/` triggers the sync hook → POST `/api/sync` with `{site, files}`. The server writes the files atomically into `sites/<name>/source/`. **Sync only touches the staging area.**

- Reflected in **preview immediately** (the renderer reads `source/`).
- **Not visible on production** until you `/publish`.

Validation runs before any write. A bad page (missing `title`, invalid section type) rejects the whole batch with `{error, path, field}`.

### `/publish [message]`

Snapshots `source/` to `publishes/<new-id>/source/`, writes `meta.json`, then atomically flips `current.json` to point at the new snapshot. **Atomic** — the renderer always sees a consistent `current.json` pointer (uses temp-file + rename).

- `<new-id>` is `<ISO timestamp>-<random8>` so two publishes in the same millisecond can't collide.
- A per-site mutex serialises `/sync`, `/publish`, and `/rollback` so they can't interleave.
- On failure mid-copy, the `.tmp-<id>/` staging dir is `rm`-ed and `current.json` stays pointing at the prior snapshot.

### `/diff`

GET `/api/diff?site=<name>` — compares `source/` against `publishes/<current>/source/`. Returns `{added, modified, deleted}`. Use before `/publish` to confirm what's about to go live.

### `/rollback [snapshot]`

Flips `current.json` to a prior snapshot. **Does NOT touch `source/`** — your unpublished edits stay intact.

- Refuses if the target snapshot's `source/` directory is missing (corrupted snapshot).
- Returns the meta of the rollback target.

Roll forward by either `/publish`-ing again (new snapshot) or `/rollback`-ing to a later snapshot from `/api/publishes`.

### `/visibility public|private`

Controls who can view `<site>.supa.page`. Independent of `/publish` — toggling visibility doesn't re-publish.

- `private` (default for new sites): non-org-members get redirected to `/signin`.
- `public`: anyone can view.

Preview (`?preview=<site>`) is **always reachable** if you know the URL — visibility only gates the production URL.

## The mental model

> **`source/` is your working tree; `publishes/` is your history; `current.json` is HEAD.**

This is git mapped onto filesystem semantics:

| Git | supa.page |
|---|---|
| working tree | `source/` |
| commit | `publishes/<id>/` |
| HEAD | `current.json` |
| `git status` | `/diff` |
| `git commit` | `/publish` |
| `git checkout <commit>` | `/rollback <snapshot>` |

The mapping breaks in two places:
- Snapshots are immutable directory copies, not deltas. Disk grows with publish count (retention policy is on the v0.1.4 roadmap).
- There's no branching. Single-track linear history.

## Production routing

A request to `<name>.supa.page` flows:

1. Caddy receives the connection, terminates TLS via on-demand cert.
2. Hono dispatcher routes by Host header — `<name>.supa.page` → `publicApp`.
3. `publicApp` reads `current.json` to find the active snapshot.
4. Renders the page JSON from `publishes/<current>/source/`.

If `current.json` is missing or points at a non-existent snapshot, the site 404s. Sites auto-publish their initial scaffold on `/new` to avoid this.

## Preview routing

A request to `<server>/?preview=<name>` flows:

1. Hono dispatcher routes by query param.
2. `publicApp` reads `source/` directly (no `current.json` lookup).
3. Renders the latest staged content.

Preview bypasses visibility. The URL is unguessable enough (it requires the site name) to be acceptable for an alpha; v0.2 will add an explicit preview-token mechanism.

## Common failure modes

### "My edit isn't on the live URL"

Either:
- You didn't `/publish` after the sync — check `/diff` to confirm.
- `visibility = private` and you're not signed in — `/visibility public` or sign in.
- The site has no `current.json` yet (only happens if `/new` was interrupted). Run `/publish` once to seed it.

### "Why is the prod URL 404-ing?"

`current.json` points at a snapshot whose `source/` was manually deleted on the box. Roll back to a different snapshot from `/api/publishes`.

### "I synced but `/diff` still shows changes"

`/diff` shows changes between `source/` and the **current published snapshot**. If you've never `/publish`ed since the change, the diff is correct — `source/` is ahead of prod.

### "Two `/publish`es in fast succession — which one wins?"

The second. Per-site mutex serialises publishes; the second waits for the first to finish, then runs. Both snapshots end up in `publishes/`; `current.json` points at the second.

## The Stop hook

If you finish a session with staged changes not pushed to prod, the Stop hook nudges:

> supa.page: 3 staged change(s) in 'my-site' aren't published yet. Run /publish to push them live, or leave them staged on purpose.

Never blocks. You can leave staging dirty intentionally.

## Anti-patterns

- **Editing `publishes/<id>/source/` directly.** Don't. Those directories are immutable snapshots. The next `/publish` will overwrite the wrong one if you do.
- **Calling `/publish` from a loop.** `/rollback`, `/domain-remove`, and `/signout` set `disable-model-invocation`, but `/publish` doesn't — it's safe in principle but creates one snapshot per call. Disk fills up.
- **Treating `/preview` as a separate publish.** Preview reads `source/`. If sync hasn't fired, preview is stale.

## Additional resources

- **`references/snapshot-internals.md`** — deeper dive on the publish atomicity guarantees + concurrency.
- **`examples/typical-day.md`** — annotated walk-through of an edit-sync-diff-publish session.
