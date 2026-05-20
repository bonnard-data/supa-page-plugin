# Plugin testing matrix

Per-command edge-case coverage for manual QA during release prep. None of these run automatically. The server-side test suite (`bun test` from the repo root, 248 tests in v0.4.0) covers correctness of the API surface that backs each command.

For each command, the matrix covers four failure modes:

- **EMPTY** — command invoked with no `$ARGUMENTS` when it needs one
- **NOT_AUTHED** — MCP tool call returns 401 (no OAuth token, or token revoked)
- **NETWORK_DOWN** — `supa.page/mcp` unreachable
- **MALFORMED_INPUT** — bad shape (domain, slug, etc.)

Auth + token-refresh is handled by Claude Code's MCP machinery — the plugin never sees a session file. The NOT_AUTHED message in every skill is the same: "Open `/mcp` and authenticate."

## /new

| Mode | Expected |
|---|---|
| EMPTY | Asks the user for a site name (interactive) |
| NOT_AUTHED | Tell user to `/mcp` → Authenticate. |
| Bad name (UPPERCASE, has space, starts with -, >64 chars) | Reject locally with the rule and ask again. |
| 409 (`already taken`) | Tell user the name is taken; ask for another. |
| `no organization` | Direct user to sign up via the dashboard first. |

## /edit-page

| Mode | Expected |
|---|---|
| EMPTY | Resolves site via `list_sites` + ask; resolves slug via `list_pages` + ask. |
| New slug | `get_page` 404 → start from a fresh object `{slug, title, sections: []}`. |
| Malformed page | Pre-flight validator fails → present the error, don't upsert. |
| Successful upsert | Tell user it landed in drafts; suggest `/diff` + `/publish`. |

## /edit-post

| Mode | Expected |
|---|---|
| Same as /edit-page | Plus: posts default to `published: false`; remind the user. |

## /delete-page / /delete-post

| Mode | Expected |
|---|---|
| `disable-model-invocation: true` | Subagents can't trigger; only a user does. |
| AskUserQuestion confirms | "Yes, delete" / "Cancel". Default to cancel on ambiguous response. |
| Last remaining `index` page | `delete_page` refuses; surface the error. |

## /discard-changes

| Mode | Expected |
|---|---|
| Empty diff | "No draft changes — nothing to discard." |
| Confirm before reset | Show diff first; then AskUserQuestion. |
| Scope: site_config | Resets just the `site_config_draft` row. |

## /update-theme

| Mode | Expected |
|---|---|
| No read tool for site_config | Skill asks user what they want to change. |
| Unknown token in `theme_overrides` | Pre-validator warns; the server drops it silently. |
| Unsafe value (`;`, `{`, `}` in a value) | Pre-validator fails. |

## /publish

| Mode | Expected |
|---|---|
| EMPTY (no message) | AskUserQuestion gathers a message. |
| Empty diff | Still allowed — publish is idempotent. Surface "no draft changes promoted." |
| Server 500 | Surface the response body. |

## /diff

| Mode | Expected |
|---|---|
| Empty diff | "No draft changes — main is up to date." |
| Many changes | Render grouped by content type; no truncation. |

## /preview

| Mode | Expected |
|---|---|
| EMPTY | Resolve site via context or `list_sites` + ask. |
| Just prints URL | Local-only; no auth required for the URL itself. |
| macOS | Offer to `open <url>` via Bash. |

## /list

| Mode | Expected |
|---|---|
| NOT_AUTHED | Tell user to `/mcp` → Authenticate. |
| Zero sites | "No sites yet. Run /new <name> to create your first." |

## /status

| Mode | Expected |
|---|---|
| EMPTY | Resolve site via context or `list_sites` + ask. |
| Site not found | Surface 404. |

## /visibility

| Mode | Expected |
|---|---|
| EMPTY $ARGUMENTS | AskUserQuestion with Public / Private options. |
| Bad value ("nope") | Local check rejects. |

## /domain-add

| Mode | Expected |
|---|---|
| EMPTY $ARGUMENTS | Ask for the domain. |
| Bad shape (no TLD, contains /, starts with -, >253 chars, https:// prefix) | Local regex rejects before API. Show the rule. |
| *.supa.page host | Local check rejects ("Cannot register a *.supa.page host"). |
| 409 (already claimed) | Surface. |
| Cloudflare proxy | initial status comes back error_dns; user can /domain-recheck after disabling the proxy. |

## /domain-list

| Mode | Expected |
|---|---|
| No domains | "No custom domains for `<site>`. Add one with /domain-add `<site>` `<domain>`." |
| Mixed statuses | Render each with the right indicator (✓ ⏳ ⚠ ✗). |

## /domain-remove

| Mode | Expected |
|---|---|
| `disable-model-invocation: true` | Subagents can't trigger. |
| 404 | "Domain not registered, or not owned by you." |
| Bad shape | Local regex check rejects. |

## /domain-recheck

| Mode | Expected |
|---|---|
| dns_verified / active | "✓ <domain> is configured correctly." |
| pending_dns | "⏳ <domain> isn't resolving yet. DNS may still be propagating." |
| error_dns | "⚠ <domain> resolves to <observed>, but we expected <expected>." |

## /signin · /signout

| Mode | Expected |
|---|---|
| /signin | Tells the user to open `/mcp` → Authenticate. Optionally calls `whoami` to verify. |
| /signout | Tells the user to open `/mcp` → Clear authentication. |

## How to run this matrix manually

```bash
# 1. Spin up a fresh dev server in one terminal
DB_PATH=":memory:" bun run dev

# 2. In another terminal, install the plugin in dev mode and walk through
#    each command above. Confirm output matches expected for each row.

# 3. Specifically test the cross-platform footguns:
#    - macOS: confirm any Bash invocations work under zsh and bash.
#    - Linux: full pass.
#    - Windows: MCP is HTTP-only, no shell dependency — just sanity check.
```

## What's NOT covered automatically

- **OAuth provider end-to-end** — DCR + auth-code + token exchange + MCP tool call. Verified manually via the SSE/MCP smoke script.
- **Real DNS / Caddy / Let's Encrypt** — verified on the Hetzner box by hand. No automated end-to-end.
- **Resend email delivery** — OTP emails must actually reach the inbox. Tested manually per release.
