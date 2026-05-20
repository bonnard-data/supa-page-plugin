# Changelog

All notable changes to the supa.page plugin. This project adheres to
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.4.0] — 2026-05-20

### Typed CRUD + drafts model

v0.2.0 — v0.3.x stored every site as a `source/` directory on disk per site
and shipped content edits through one big `sync_files` MCP tool that
batched file writes. Publishes snapshotted the whole tree; `rollback_site`
flipped a `current.json` pointer between snapshots.

v0.4.0 makes the platform database the source of truth and gives every
content type its own typed CRUD surface. The on-disk `source/` tree, the
snapshot history, and the single batch-write tool are gone.

**New tool surface (23 tools, up from 14):**

```
Identity:           whoami
Sites:              list_sites · get_site · create_site · set_visibility
                    update_site_config            (NEW)
Pages:              list_pages · get_page · upsert_page · delete_page   (ALL NEW)
Posts:              list_posts · get_post · upsert_post · delete_post   (ALL NEW)
Lifecycle:          diff_site · publish_site · discard_changes          (discard NEW)
Domains:            list_domains · add_domain · remove_domain · recheck_domain
```

**Removed:**
- `sync_files` — replaced by typed CRUD per content type.
- `rollback_site` — no snapshot history in v0.4.0. Edit forward and re-publish.
- `list_publishes` — the dashboard remains the way to inspect publish history.

**Drafts + publish model:**

Edits land in `*_draft` tables. `publish_site` promotes drafts → main in
a single SQLite transaction, then re-renders the static HTML served by
Caddy. `<site>.supa.page` updates immediately on publish (within ~100ms;
no snapshot-copy step). `discard_changes` throws away drafts without
touching main.

**Live preview SSE:**

The preview channel is now `<site>.supa.page/?preview=1`. It reads from
the `*_draft` tables and opens an SSE channel — any open preview tab
reloads automatically when a draft row changes.

**Plugin skills (new):**
- `/edit-page` — read-modify-write on a page row
- `/edit-post` — same for blog posts
- `/delete-page`, `/delete-post` — gated with confirmation
- `/discard-changes` — show diff, confirm, reset drafts
- `/update-theme` — patch `site_config` (theme, theme_overrides, header, footer)

**Plugin skills (removed):**
- `/rollback` — no rollback tool to wrap.

**Knowledge skills updated:**

Every knowledge skill (`section-catalogue`, `theme-tokens`, `posts-and-blog`,
`custom-components`, `custom-domains`, `publishing-workflow`) has been
rewritten to remove references to `source/` directories, `sync_files`,
and snapshot history. Examples + references reflect the typed-object
model. Local validators (`validate-section.js`,
`validate-frontmatter.js`, `validate-theme-overrides.js`) still ship —
they now validate the typed objects you pass to `upsert_*`.

**Agents updated:**

- `site-author` now authors via `upsert_page` / `upsert_post` /
  `update_site_config` and reads existing content via `get_page` /
  `get_post`.
- `content-validator` reads pages + posts via the typed CRUD surface
  and runs the same per-shape validators against each fetched row.

### Breaking changes for v0.2.x / v0.3.x users

- **`sync_files` is gone.** Agents that called it must switch to
  `upsert_page`, `upsert_post`, and `update_site_config`. Each call takes
  the full typed object and replaces the matching draft row.
- **`rollback_site` and `list_publishes` are gone.** If a publish was a
  mistake, edit forward and publish again. The dashboard still surfaces
  the publish log for audit.
- **No on-disk `source/` tree.** There's nothing to sync. Pages and posts
  are SQLite rows; content lives only on the server.
- **Preview URL changed.** `https://supa.page/?preview=<site>` →
  `https://<site>.supa.page/?preview=1`.

## [0.2.0] — 2026-05-20

### MCP-only — bash auth + bash skills + sync hook removed

v0.1.x ran a parallel auth and tool surface — `/signin` device flow wrote
`~/.config/supa-page/session.json`; 17 bash scripts under
`plugin/scripts/` re-implemented what the platform-side MCP server
already exposed. That made sense before MCP shipped. With v0.1.5 wiring
the MCP into the plugin manifest, the bash duplicates became dead code.

v0.2.0 deletes them:

**Removed:**
- `plugin/lib/api.sh` (~200 lines)
- `plugin/scripts/*.sh` — all 17 action scripts (list, status, diff, new,
  publish, visibility, rollback-fetch, rollback-act, domain-add,
  domain-list, domain-remove, domain-recheck, signin-init, signin-poll,
  signin-welcome, signout, preview)
- `plugin/hooks/scripts/sync.sh` — PostToolUse auto-sync
- `plugin/hooks/scripts/session-start.sh` — resume banner
- `plugin/hooks/scripts/stop-check.sh` — unsynced-changes warning
- `~/.config/supa-page/session.json` — the BA session token file is no
  longer read by anything in the plugin. Safe to leave on disk; safer to
  `rm` it.

**Kept:**
- `plugin/hooks/scripts/secret-scan.sh` (PreToolUse) — local-only,
  doesn't depend on auth.

**Converted:**
- Every action skill in `plugin/skills/*/SKILL.md` is now a thin
  markdown orchestrator that routes to the matching MCP tool via
  `allowed-tools` frontmatter. ~10 lines instead of ~30.

### Server-side: new `create_site` MCP tool

The MCP server registered 13 tools in v0.1.3 but had no
`create_site` — that path lived only in the legacy bash plugin. v0.2.0
closes the gap. Site creation now goes through MCP like every other
operation.

### Auth: one model, OAuth 2.1

Sign-in is now exclusively handled by Claude Code's MCP OAuth flow:

1. Install plugin → Claude Code discovers `plugin/.mcp.json`
2. First MCP tool call → 401 from `/mcp` → Claude Code does
   RFC 7591 dynamic client registration + browser authorization_code
   flow with PKCE
3. Token cached in Claude Code's MCP state; refreshed automatically
4. `/mcp` dialog → "Clear authentication" replaces `/signout`

For users with multiple MCP clients (Cursor, Claude desktop, custom
agents), each client does its own OAuth dance — there's no shared
token across clients (by design — audience-bound per RFC 8707).

### Breaking changes for v0.1.x users

- **`/signin` device flow is gone.** The `/signin` skill remains but
  now just points to the MCP dialog. Existing `~/.config/supa-page/`
  files are ignored.
- **Auto-sync on Edit/Write is gone.** Agents must explicitly call the
  `sync_files` MCP tool to push file changes. The MCP tool batches
  many files in one call — generally more efficient than the
  per-edit hook anyway.
- **`.supa-page.json` markers are no longer required.** The plugin no
  longer walks up looking for them. Agents track "which site am I
  working on?" from conversation context.
- **`session-start` banner is gone.** The `/mcp` dialog shows auth
  status.

### Net diff

- Plugin shrinks from ~900 lines of bash + 20 skills to ~80 lines of
  markdown skills + the secret-scan hook.
- One auth model. One tool surface. Same functionality.

## [0.1.5] — 2026-05-20

### MCP server — wired into the plugin manifest

The supa.page server has shipped a Streamable HTTP MCP endpoint at
`https://supa.page/mcp` since v0.1.3 (server commit `50eb69b`), but the
plugin never advertised it to Claude Code. Users who installed the plugin
got skills only; the MCP tools were reachable only via a manual
`/mcp add` against the URL.

This release adds `plugin/.mcp.json` (the docs-recommended Method 1)
so installing the plugin auto-registers the remote MCP and Claude Code
discovers the 13 tools automatically:

```
mcp__plugin_supa-page-plugin_supa-page__whoami
mcp__plugin_supa-page-plugin_supa-page__list_sites
mcp__plugin_supa-page-plugin_supa-page__get_site
mcp__plugin_supa-page-plugin_supa-page__list_publishes
mcp__plugin_supa-page-plugin_supa-page__diff_site
mcp__plugin_supa-page-plugin_supa-page__sync_files
mcp__plugin_supa-page-plugin_supa-page__publish_site
mcp__plugin_supa-page-plugin_supa-page__rollback_site
mcp__plugin_supa-page-plugin_supa-page__set_visibility
mcp__plugin_supa-page-plugin_supa-page__list_domains
mcp__plugin_supa-page-plugin_supa-page__add_domain
mcp__plugin_supa-page-plugin_supa-page__remove_domain
mcp__plugin_supa-page-plugin_supa-page__recheck_domain
```

**Auth:** OAuth 2.1 with dynamic client registration (RFC 7591), PKCE
(S256), and audience-bound access tokens (RFC 8707). Claude Code handles
the entire flow automatically — first MCP tool call triggers a browser
authorization step against `https://app.supa.page`, with consent scoped
to `mcp:read`, `mcp:sites:write`, `mcp:posts:write`, `offline_access`.

**Skills + MCP coexist.** The skills (`/new`, `/publish`, etc.) remain
unchanged — they're still the right interface when you want kebab-case
slash commands from the CLI. The MCP tools are what subagents and
external MCP clients (Cursor, Claude desktop) bind to.

**No breaking changes.** Plugin description and keywords already
mentioned MCP; this release makes the claim accurate.

## [0.1.4] — 2026-05-20

### Architecture refactor — commands → skills + scripts

Every slash command moved from the legacy `commands/` layout to the
docs-recommended `skills/<name>/SKILL.md` layout, with the real bash logic
extracted to `scripts/<name>.sh`. The skill markdown is now a thin
orchestrator that invokes the script via the `!`bash …`` prefix; the
harness runs the script in actual `bash` (honouring the shebang) and
substitutes its stdout into the prompt.

This fixes a real portability bug that hit any macOS user with the default
zsh shell: `lib/api.sh` was sourced from the agent's interactive shell, and
its `local status` declaration collided with zsh's readonly `$status`
special parameter, causing every command except `/signin`, `/signout`, and
`/preview` to fail immediately.

The new architecture moves the shell-of-record decision into the shebang
on each script. Whatever shell the agent runs in (zsh, bash, anything),
the script always runs in bash.

**File layout changes:**

```
plugin/
├── commands/             # DELETED
├── lib/api.sh            # zsh-safe (renamed `local status` → `local http_status`)
├── scripts/<cmd>.sh      # NEW — real logic, #!/usr/bin/env bash
└── skills/<cmd>/SKILL.md # NEW — thin orchestrator
```

**No behaviour changes.** Every command behaves identically from the user's
perspective. The same `/list`, `/new`, `/publish`, etc. still work; they
just route through the new architecture.

**Internal:** scripts emit user-facing messages on stdout, diagnostics on
stderr. Exit code 64 is reserved for "needs input from the user" — the
skill is expected to AskUserQuestion and re-invoke the script with the
answer. Exit code 2 is reserved for "session expired, suggest /signin".

## [0.1.3] — 2026-05-20

### Marketplace

- **Renamed marketplace org** `bonnard-data` → `supa-page`. Existing testers
  installed via the old name need to re-add the marketplace:

  ```
  /plugin uninstall supa-page-plugin@bonnard-data
  /plugin marketplace remove bonnard-data
  /plugin marketplace add supa-page
  /plugin install supa-page-plugin@supa-page
  ```

  The old cache directory (`~/.claude/plugins/cache/bonnard-data/`) can be safely
  `rm -rf`'d.

### Auth — hard cut

- **`.supa-page.json` is now secretless.** Pre-v0.1.3 the file carried a
  per-site `token`. As of v0.1.3 it's just `{ "site", "server" }`. The plugin
  authenticates with the user's Better Auth session token from
  `~/.config/supa-page/session.json` and sends `site` in every request body.
- **Single source of credential.** Run `/signin` once; every command picks up
  the session. Old configs with a stale `token` field still work — the field
  is ignored and the plugin emits a one-time hint to remove it.
- Anonymous site creation (POST /api/sites without auth) is gone.

### New commands

- **`/visibility public|private`** — toggles site visibility via the new
  enum endpoint (`PUT /api/sites/:name/visibility`). Falls back to an
  interactive picker when called without args. Future modes (`password`,
  `allowlist`, `sso`) extend the same enum.

### Command UX

- Every command now declares `allowed-tools` and `argument-hint` frontmatter
  for safer auto-completion + reduced permission prompts.
- `/rollback`, `/domain-remove`, `/signout` set `disable-model-invocation: true`
  so background loops and subagents can't trigger destructive actions without
  a human in the loop.
- `/rollback` now uses `AskUserQuestion` to render a clean snapshot picker
  (label = timestamp, description = publish message) when called without an
  argument.
- `/visibility` uses `AskUserQuestion` to render the Public/Private option list.
- Read-only commands (`/list`, `/status`, `/domain-list`, `/domain-recheck`,
  `/diff`, `/preview`) run with `model: haiku` for faster latency.
- `/new` description trimmed; rejects target directories that already contain
  a `.supa-page.json`.
- Domain format validation (RFC 1035-ish) in `/domain-add` and
  `/domain-remove` rejects malformed input before hitting the API.
- All commands carry a top-of-file HTML doc block (USAGE / REQUIRES / EFFECT
  / DANGER as applicable) so the agent can grep for the contract.
- Error messages now include recovery guidance ("Run `/signin` first, then
  rerun `/diff`").

### Shared library

- New `lib/api.sh` sourced from every command. Centralises:
  - `supa::ensure_deps` — verifies `curl` + `jq` are on PATH
  - `supa::find_site_config` — walks up from `$PWD` for `.supa-page.json`
  - `supa::ensure_signed_in` — reads the BA session token
  - `supa::api METHOD PATH [BODY]` — curl wrapper with structured
    `<status>\n<body>` output, returning 0 on 2xx, 2 on 401, 1 otherwise.
- All curl-in-command duplication is gone; commands stay under 100 lines.

### Sync hook

- The PostToolUse `sync.sh` script reads the bearer from
  `~/.config/supa-page/session.json` (not the per-site token, which is gone).
- Sends `{site, files}` in the body.
- 401/403/413/000 each get a specific recovery message instead of a generic
  "FAILED" line.

### Manifest

- `plugin.json` bumped to 0.1.3; added `author` (Max Mealing
  `<max@bonnard.ai>`) and `keywords`.
- `marketplace.json` synced to 0.1.3.
- Plugin gains a `LICENSE` file (MIT).

### Namespace clashes

- `/new`, `/publish`, `/status`, `/list`, `/diff`, `/preview` are generic names
  and may collide with other Claude Code plugins. Each command's notes
  document the fallback form `/plugin:supa-page-plugin:<command>`.

## [0.1.2] — 2026-05-19

- Bumped marketplace.json for the upcoming mirror release.

## [0.1.1] — 2026-05-18

- Surfaced the `staging_public` dashboard step in `/new` and `/publish`.
- Sitemap now enumerates `pages/*.json`; posts must declare `published: true`
  in frontmatter.
- Renderer hardening + `/api/welcome` plugin-driven onboarding endpoint.

## [0.1.0] — 2026-05-17

- Initial public release of the `supa-page-plugin` via the
  `bonnard-data/supa-page-plugin` marketplace.
