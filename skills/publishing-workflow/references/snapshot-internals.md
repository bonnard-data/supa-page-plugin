# Snapshot internals

The atomicity + concurrency guarantees the server makes when publishing.

## Snapshot ID format

```
<ISO 8601 timestamp with `:` → `-`>-<8 hex chars>
2026-05-20T15-30-42.000Z-deadbeef
```

The random suffix guards against same-millisecond collisions. Without it, two simultaneous `/publish` calls would create the same directory name, and `mkdir({recursive: true})` would silently merge their contents.

`isValidSnapshotId` regex (server-side):

```
^\d{4}-\d{2}-\d{2}T\d{2}-\d{2}-\d{2}\.\d{3}Z(?:-[0-9a-f]{8})?$
```

The legacy form (no suffix) still parses for pre-v0.1.3 snapshots that exist on disk.

## Publish atomicity

The publish dance:

1. `mkdir publishes/.tmp-<id>/` — staging directory with a `.tmp-` prefix so it's filtered out of `listPublishes`.
2. `cp -r source/ publishes/.tmp-<id>/source/` — full directory copy.
3. `writeFile publishes/.tmp-<id>/meta.json` — `{snapshot, timestamp, message}`.
4. `rename publishes/.tmp-<id>/ → publishes/<id>/` — atomic on the same filesystem.
5. `writeCurrentAtomic` — write to `.current.<rand>.tmp`, rename to `current.json`.

Failure modes:

- **Crash before step 4** → `.tmp-<id>/` is orphaned on disk but `current.json` is untouched. Production renders the prior snapshot. The orphan dir is hidden from `listPublishes`. A follow-up garbage-collect step (v0.1.4) sweeps these.
- **Crash between steps 4 and 5** → New snapshot exists but `current.json` still points at the prior one. Production unchanged. Customer just sees one extra entry in `/api/publishes` they can roll forward to.

The reader (production renderer) only ever sees `current.json` after both the snapshot is fully assembled AND the pointer is flipped. Never reads `.tmp-` directories.

## Per-site mutex

`snapshots.ts` holds a `Map<siteName, Promise>` chain that serialises:

- `publish(site)` calls
- `rollback(site)` calls
- `/api/sync` writes for that site

So:

- Two `/publish` calls in flight → run back-to-back, both succeed, second is the new HEAD.
- `/sync` mid-`/publish` → the sync waits for publish to finish copying, then writes to `source/`. The published snapshot reflects the state at the moment publish started.
- Two `/sync` calls in flight → applied in order. The pre-v0.1.3 race that left files 1..N-1 written when file N validated bad is gone (validation moved to a pre-pass; whole batch rejects atomically).

The mutex is per-site, so unrelated sites don't block each other.

## `current.json` write atomicity

```ts
writeCurrentAtomic(root, snapshot):
  tmp = `.current.${random8}.tmp`
  writeFile(tmp, JSON.stringify({snapshot}))
  rename(tmp, 'current.json')
```

`rename` is atomic on POSIX (same filesystem). Readers always see the old contents or the new contents, never partial.

There's no `fsync` between the write and the rename, so under hard power loss the rename can be visible while the file body is zero. Indie scale: acceptable. v0.1.4 will add `fsync` for robustness.

## Rollback safety

Before flipping `current.json`, rollback verifies:

```ts
stat(publishes/<snapshot>/source/site.json)
```

If that file is missing (the snapshot directory was manually deleted, leaving only `meta.json`), rollback returns null and `current.json` stays pointing at the prior snapshot.

Without this check, manually-deleted snapshots with leftover meta.json would silently 404 the whole production site.

## Retention

Pre-v0.1.4: snapshots accumulate forever. At ~50KB per snapshot for a typical page-JSON site, this is years of headroom on a single VPS.

The retention policy on the v0.1.4 roadmap:
- Keep the last N=50 snapshots.
- Keep everything younger than 90 days.
- Keep the current snapshot.
- Keep any explicitly "tagged" snapshot (future tagging feature).
- Sweep `.tmp-<id>/` orphans nightly.

## Diff implementation

`/api/diff?site=<name>` walks `source/` and `publishes/<current>/source/`, returns:

```ts
{
  added: string[];     // in source/, not in published
  modified: string[];  // in both, different content
  deleted: string[];   // in published, not in source/
}
```

Modified comparison is full string read + compare. For typical-size JSON + Markdown content this is fast (KB-scale files). When asset hosting ships in v0.2 the comparator will switch to a size-then-hash short-circuit to avoid reading large binaries.

## What the platform does NOT guarantee

- **Cross-site atomicity.** If site A and site B publish at the same instant, there's no global lock — they're independent.
- **Cross-region replication.** Single Hetzner box; no DR replica.
- **fsync durability.** A hard power loss within ~30s of a publish can lose the publish (file system journal helps but isn't guaranteed). Litestream → R2 is on the roadmap.
- **Backward compat of legacy snapshot IDs.** Pre-v0.1.3 snapshots (no random suffix) still parse via the older regex; the catalogue regex accepts both forms. v0.2 may drop legacy compatibility — keep a backup if you need long retention.
