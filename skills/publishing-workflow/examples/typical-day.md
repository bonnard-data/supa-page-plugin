# A typical edit-sync-publish session (v0.2.0)

Annotated walk-through of a normal supa.page workflow. Read it once; it'll
inform what the agent does the next time someone says "update the hero copy
and ship it."

## 0. Starting state

The user has already authenticated this Claude Code session via `/mcp` →
**Authenticate**. The 14 supa.page MCP tools are available. There's no
local config file, no `.supa-page.json` marker — the agent tracks
"which site are we working on?" from conversation context.

## 1. Edit a section

User: "Update the hero headline on `my-product` to 'Ship 10x faster' and
change the CTA to 'Try it free'."

Agent calls `sync_files` with the patched page JSON:

```json
{
  "site": "my-product",
  "files": [
    {
      "path": "pages/index.json",
      "content": "{ \"title\": \"My product\", \"sections\": [ { \"type\": \"hero\", \"title\": \"Ship 10x faster\", \"cta\": { \"label\": \"Try it free\", \"href\": \"/signup\" } } ] }\n"
    }
  ]
}
```

Response: `{"synced": 1, "removed": 0, "warnings": []}`.

The new copy is live in **preview** (`https://supa.page/?preview=my-product`)
but not yet on production.

## 2. Diff before publish

User: "What's changed since last publish?"

Agent calls `diff_site({site: "my-product"})`:

```
~ pages/index.json     (modified)
```

Just the one file. Looks right.

## 3. Publish

User: "Ship it — message 'headline + CTA copy update'."

Agent calls `publish_site({site: "my-product", message: "headline + CTA copy update"})`:

```
{
  "snapshot": "2026-05-20T15-30-42.000Z-deadbeef",
  "message": "headline + CTA copy update"
}
```

Production now serves the new headline.

## 4. Realise the CTA href was wrong

User: "Wait, the signup URL is /start, not /signup."

Agent edits the file again via `sync_files`, then calls `publish_site` again:

```
{
  "snapshot": "2026-05-20T15-31-15.000Z-cafe0001",
  "message": "fix CTA href"
}
```

Two snapshots in the history now.

## 5. The next day — roll back a bad release

User: "I broke pricing this morning. Roll back."

Agent calls `list_publishes({site: "my-product"})`, surfaces the recent
snapshots, asks the user which one to roll back to, then calls
`rollback_site({site, snapshot})`. `current.json` flips back; production
serves the prior snapshot. The staging tree is untouched — the user can
fix what they broke and re-publish.

## Mental model recap

- **`sync_files`** updates staging on the server. Visible in preview immediately.
- **`publish_site`** snapshots staging → makes it production.
- **`rollback_site`** changes which snapshot is "live" — doesn't touch staging.
- **Source/** is the staging tree; **publishes/** is the history;
  **current.json** is the pointer the renderer follows.
