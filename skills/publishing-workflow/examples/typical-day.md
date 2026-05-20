# A typical edit-diff-publish session (v0.4.0)

Annotated walk-through of a normal supa.page workflow under the typed CRUD + drafts model. Read it once; it'll inform what the agent does the next time someone says "update the hero copy and ship it."

## 0. Starting state

The user has already authenticated this Claude Code session via `/mcp` → **Authenticate**. The 23 supa.page MCP tools are available. There's no local config file, no source/ tree on disk — the agent tracks "which site are we working on?" from conversation context.

## 1. Edit a section

User: "Update the hero headline on `my-product` to 'Ship 10x faster' and change the CTA to 'Try it free'."

Agent reads the current page first (so it can patch precisely without losing other sections):

```
get_page({site: "my-product", slug: "index"})
```

Returns the full page object. Agent patches it locally — changes the hero `title` and `cta.label` — then writes it back:

```
upsert_page({
  site: "my-product",
  slug: "index",
  page: {
    title: "My product",
    sections: [
      { type: "hero", title: "Ship 10x faster", cta: { label: "Try it free", href: "/signup" } },
      ...
    ]
  }
})
```

Response: `{ ok: true, draft: true }`.

The new copy is live in **preview** (`https://my-product.supa.page/?preview=1`) but not yet on production. Any open preview tab reloads automatically via SSE.

## 2. Diff before publish

User: "What's changed since last publish?"

Agent calls `diff_site({site: "my-product"})`:

```
{
  pages: { added: [], modified: ["index"], deleted: [] },
  posts: { added: [], modified: [], deleted: [] },
  site_config: "unchanged"
}
```

Just the one page. Looks right.

## 3. Publish

User: "Ship it — message 'headline + CTA copy update'."

Agent calls `publish_site({site: "my-product", message: "headline + CTA copy update"})`:

```
{
  publish_id: 42,
  message: "headline + CTA copy update",
  promoted: { pages: 1, posts: 0, site_config: false }
}
```

Production serves the new headline within ~100ms — the static HTML re-render runs as part of the publish transaction.

## 4. Realise the CTA href was wrong

User: "Wait, the signup URL is /start, not /signup."

Same loop: `get_page` → patch → `upsert_page` → `publish_site` again.

```
{ publish_id: 43, ... }
```

No rollback semantics — the second publish overwrites the first on production. The publish log keeps both entries for audit, but there's no `/rollback` command in v0.4.0.

## 5. Cleared draft drift

User: "I edited the pricing page yesterday but never published. Throw the drafts away."

Agent calls `diff_site` to confirm what would be lost, summarises it ("pricing.json modified — 3 sections changed"), confirms with the user, then calls:

```
discard_changes({site: "my-product", kind: "page", slug: "pricing"})
```

The `pages_draft` row for `pricing` is reset to the current `pages` row. Live main is untouched.

## Mental model recap

- **`upsert_page` / `upsert_post` / `update_site_config`** write to draft tables. Visible in preview (`?preview=1`) immediately + SSE reload.
- **`publish_site`** promotes drafts to main + re-renders static HTML. Live URL updates immediately.
- **`discard_changes`** resets draft rows to match main. Main is never touched.
- **No snapshot history.** No `/rollback`. Edit forward and re-publish.
