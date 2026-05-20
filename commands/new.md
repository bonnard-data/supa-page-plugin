---
name: new
description: Create a new supa.page site and scaffold local files
argument-hint: [site-name]
allowed-tools: Bash, Write
model: sonnet
---

<!--
USAGE:        /new my-site
REQUIRES:     /signin first; jq + curl available; cwd not already a site dir
WRITES:       <site-dir>/.supa-page.json, source/site.json, source/pages/index.json
NOTE (v0.1.3): no per-site token. The plugin authenticates via your BA session
              (~/.config/supa-page/session.json) and sends `site` in every body.
-->

The user wants to create a new supa.page site.

## What to do

1. **Source the shared helper** so we get `supa::ensure_deps`, `supa::ensure_signed_in`, and the typed env vars (`SUPA_TOKEN`, `SUPA_SERVER`):

   ```bash
   source "${CLAUDE_PLUGIN_ROOT}/lib/api.sh"
   supa::ensure_deps || exit 1
   supa::ensure_signed_in || {
     echo "Run /signin first, then re-run /new <name>." >&2
     exit 2
   }
   ```

2. **Pick the site name.** If `$ARGUMENTS` is non-empty, use it. Otherwise ask the user. Must be lowercase, kebab-case, 1–64 chars, start and end with alphanumeric (e.g. `vibrant-otter`). Reject anything else and ask again.

3. **Idempotency.** Refuse if the target dir already contains `.supa-page.json`:

   ```bash
   SITE_DIR="${PWD}/<name>"
   [ -f "$SITE_DIR/.supa-page.json" ] && {
     echo "supa.page: $SITE_DIR is already a supa.page site." >&2
     echo "  cd into it and run /status to see the current state, or pick a different name." >&2
     exit 1
   }
   ```

4. **Reserve the site on the server** (POST `$SUPA_SERVER/api/sites` with the session bearer). Body: `{"name":"<name>"}`. Response: `{name, initial_publish, owner, org_id}` — no token field as of v0.1.3.

   ```bash
   BODY="$(jq -cn --arg n "<name>" '{name: $n}')"
   RESP="$(supa::api POST /api/sites "$BODY")"
   STATUS="$(echo "$RESP" | head -1)"
   BODY="$(echo "$RESP" | tail -n +2)"
   ```

   On 200: continue. On 409: tell the user the name is taken; ask for another. On 401: tell them to run `/signin` and stop. Otherwise surface `$BODY` and stop.

5. **Create the local directory.** Default to `./<name>/` in the current working directory unless the user specifies otherwise.

6. **Write the secretless config file.** `<site-dir>/.supa-page.json`:

   ```json
   {
     "site": "<name>",
     "server": "<server>"
   }
   ```

   No `token` field. The session bearer is read from `~/.config/supa-page/session.json` at every command invocation.

7. **Scaffold the source tree.** Create:
   - `<site-dir>/source/site.json` — `{ "title": "<name>", "description": "", "theme": "default" }`
   - `<site-dir>/source/pages/index.json` — page JSON with a **top-level `title` field** (required by the renderer + validator) plus one `hero` section:

     ```json
     {
       "title": "<name>",
       "description": "",
       "sections": [
         {
           "type": "hero",
           "title": "<name>.",
           "description": "Something is being built here."
         }
       ]
     }
     ```

     New canonical field names — `title` / `description` are the recommended shape; legacy `headline` / `sub` still accepted.

   The page-level `title` field is **required** — sync rejects pages without it with a 400 carrying `{field: "title"}`.

8. **Confirm.** Print:

   ```
   ✓ Site "<name>" created (beta — v0.1.3).
     Preview (latest published): <server>/?preview=<name>
     Live (once visibility = public): <name>.supa.page

   New sites are visibility=private by default. Toggle with /visibility public.
   ```

## Notes

- **No `.supa-page.json` secret.** Pre-v0.1.3 the file carried a per-site sync token; that's gone. Don't commit `~/.config/supa-page/session.json` — that's where the bearer lives now.
- After this command, any Write/Edit/MultiEdit inside `<site-dir>/source/` will trigger the sync hook automatically.
- **Additional pages**: write `<site-dir>/source/pages/<slug>.json` (same shape as `index.json`, with a required `title` field). They auto-route to `/<slug>` and appear in `sitemap.xml`.
- **Blog posts**: write `<site-dir>/source/posts/<slug>.md` with YAML frontmatter:

  ```yaml
  ---
  title: My post
  date: 2026-01-15
  slug: my-post
  published: true   # REQUIRED on production — drafts (omitted/false) appear in preview only
  ---
  ```

  Without `published: true`, the post is a draft: it renders only via `?preview=<site>` and is excluded from the public `/posts` archive, RSS, and sitemap.

## Namespace clashes

`/new` is a generic name and may collide with other Claude Code plugins. If you have a conflict, invoke this command as `/plugin:supa-page-plugin:new`.
