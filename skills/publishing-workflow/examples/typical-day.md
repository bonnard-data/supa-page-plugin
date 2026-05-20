# A typical edit-sync-publish session

Annotated walk-through of a normal supa.page workflow. Read it once; it'll
inform what the agent does the next time someone says "update the hero copy
and ship it."

## 0. Starting state

```
$ pwd
/Users/me/sites/my-product

$ cat .supa-page.json
{ "site": "my-product", "server": "https://supa.page" }
```

The session bearer is already cached from `/signin`. The SessionStart hook
fires when Claude Code starts and prints:

```
supa.page: signed in as max@bonnard.ai · 3 site(s) · server=https://supa.page
```

## 1. Edit a section

User: "Update the hero headline to 'Ship 10x faster' and change the CTA to 'Try it free'."

Agent uses Edit on `source/pages/index.json`:

```json
{
  "title": "My product",
  "sections": [
    {
      "type": "hero",
      "title": "Ship 10x faster",
      "cta": { "label": "Try it free", "href": "/signup" }
    }
  ]
}
```

The PostToolUse sync hook fires automatically:

```
supa.page · synced my-product/pages/index.json
```

## 2. Confirm it looks right

```
> /preview
```

Opens `https://supa.page/?preview=my-product` in the browser. The new
headline is live in **preview** but not yet on production.

## 3. Diff before publish

```
> /diff

Changes vs prod:
  ~ pages/index.json     (modified)
```

Just the one file. Looks right.

## 4. Publish

```
> /publish "headline + CTA copy update"

✓ Published — headline + CTA copy update
  snapshot: 2026-05-20T15-30-42.000Z-deadbeef
  preview:  https://supa.page/?preview=my-product
  live:     my-product.supa.page   (if visibility=public)
```

Production now serves the new headline.

## 5. Realise the CTA href was wrong

User: "Wait, the signup URL is /start, not /signup."

Agent edits the file again; sync hook fires.

```
> /publish "fix CTA href"

✓ Published — fix CTA href
  snapshot: 2026-05-20T15-31-15.000Z-cafe0001
```

Two snapshots in the publishes/ history now.

## 6. The next day — roll back a bad release

The next day, the user pushed something they regret.

```
> /rollback
```

`AskUserQuestion` shows the recent publishes:

```
1. 2026-05-21 09:00 — accidentally broke pricing
2. 2026-05-21 08:30 — fix CTA href
3. 2026-05-20 15:31 — fix CTA href
4. 2026-05-20 15:30 — headline + CTA copy update
```

Pick (2). `current.json` flips back; production serves the prior snapshot.
`source/` is untouched — the customer can fix what they broke and republish.

## 7. The Stop hook nudges

User: "OK I think we're done for the day."

But the source/ tree has the broken edits from earlier. The Stop hook
fires:

```
supa.page: 2 staged change(s) in 'my-product' aren't published yet. Run /publish to push them live, or leave them staged on purpose.
```

User decides to leave them — they'll finish tomorrow. Session ends.

## Mental model recap

- **Sync** updates staging. Visible in preview immediately.
- **Publish** snapshots staging → makes it production.
- **Rollback** changes which snapshot is "live" — doesn't touch staging.
- **Source/** is the working tree; **publishes/** is the history;
  **current.json** is HEAD.
