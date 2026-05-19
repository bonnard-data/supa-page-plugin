---
name: new
description: Create a new supa.page site — reserves the subdomain, scaffolds the local files, wires up auto-sync
---

The user wants to create a new supa.page site.

## What to do

1. **Site name.** If `$ARGUMENTS` is non-empty, use it. Otherwise ask the user. The name must be lowercase, kebab-case, 1–64 chars, start and end with alphanumeric (e.g. `vibrant-otter`). Reject anything else and ask again.

2. **Server URL.** Use `$SUPA_PAGE_SERVER` if set, otherwise default to `https://supa.page`.

3. **Reserve the site on the server.** Use Bash + curl:

   ```
   curl -sS -X POST "<server>/api/sites" \
     -H "Content-Type: application/json" \
     -d '{"name":"<name>"}'
   ```

   On 200, the response is `{"name":"...","token":"supa_..."}`. On 409, the name is taken — tell the user and ask for a different name. On other errors, surface the message and stop.

4. **Create the local directory.** Default to `./<name>/` in the current working directory unless the user specifies otherwise.

5. **Write the config file.** `<site-dir>/.supa-page.json`:

   ```json
   {
     "site": "<name>",
     "server": "<server>",
     "token": "<token>"
   }
   ```

6. **Scaffold the source tree.** Create:
   - `<site-dir>/source/site.json` — `{ "title": "<name>", "description": "", "theme": "default" }`
   - `<site-dir>/source/pages/index.json` — page JSON with a **top-level `title` field** (required by the renderer for the HTML `<title>` and OG tags) plus one `hero` section. Use this shape exactly:

     ```json
     {
       "title": "<name>",
       "description": "",
       "sections": [
         {
           "type": "hero",
           "headline": "<name>.",
           "sub": "Something is being built here."
         }
       ]
     }
     ```

   The `title` field is **required** — omitting it produces a server-side render error.

7. **Confirm.** Print:
   ```
   Site "<name>" created. Edits in <site-dir>/source/ will auto-sync.
   Preview (latest published): <server>/?preview=<name>

   Note: <name>.supa.page is private by default. To let visitors view it
   without signing in, open the dashboard and toggle "Public staging":
     <dashboard>/orgs/<your-org>/sites/<name>
   ```
   (Derive `<dashboard>` from `<server>` — `app.<apex>`. For local dev they're the same host.)

## Notes

- Do not commit `.supa-page.json` to git — it contains the sync token. Add it to `.gitignore` if a `.git` exists in the parent.
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

## If the sync hook isn't firing (manual fallback)

If you've installed the plugin via `--plugin-dir` instead of through the marketplace (e.g. during development), hooks may not register. In that case, sync manually after editing:

```bash
SERVER="$(jq -r .server <site-dir>/.supa-page.json)"
TOKEN="$(jq -r .token <site-dir>/.supa-page.json)"

# Build the payload — files is an ARRAY of {path, content}, with paths
# relative to the source/ directory (no "source/" prefix).
CONTENT="$(jq -Rs . < <site-dir>/source/pages/index.json)"
PAYLOAD="$(jq -cn --argjson c "$CONTENT" \
  '{files: [{path: "pages/index.json", content: $c}]}')"

curl -sS -X POST "$SERVER/api/sync" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD"
```

Common mistakes:
- `files` as an object (map) instead of an array — API returns `{"error":"No files"}`
- Including `source/` in the path — API returns `{"error":"Invalid path"}` or path-traversal error
- Using multipart/form-data — API returns `{"error":"Invalid JSON"}`; only JSON body is supported
