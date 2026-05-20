# Plugin testing matrix

Per-command edge-case coverage. This is a documented checklist for manual
QA during release prep — none of these run automatically. The server-side
test suite (`bun test` from the repo root, 297 tests in v0.1.3) covers
correctness of the API surface that backs each command.

For each command, the matrix covers six failure modes:

- **EMPTY** — command invoked with no `$ARGUMENTS` when it needs one
- **MISSING_CFG** — no `.supa-page.json` in the cwd chain (where applicable)
- **NOT_AUTHED** — no `~/.config/supa-page/session.json`
- **EXPIRED_TOKEN** — session.json exists but the server returns 401
- **NETWORK_DOWN** — server unreachable (curl returns 000 / timeout)
- **MALFORMED_INPUT** — bad domain shape, bad snapshot id, content >1MB, etc.

Expected behavior column shows what the user should see.

## /new

| Mode | Expected |
|---|---|
| EMPTY | Asks the user for a site name (interactive) |
| NOT_AUTHED | Print "Run /signin first, then re-run /new <name>." Exit 2. |
| Existing dir | Print "supa.page: ./<name>/ is already a supa.page site." Exit 1. |
| Bad name (UPPERCASE, has space, starts with -, >64 chars) | Reject locally with the rule and ask again. |
| 409 from /api/sites | Tell user the name is taken; ask for another. |
| 401 from /api/sites | Suggest /signin (session may have expired mid-call). |

## /publish

| Mode | Expected |
|---|---|
| MISSING_CFG | "Not in a supa.page site directory. Run /new <name> or cd into existing." |
| NOT_AUTHED | "Run /signin first, then /publish again." Exit 2. |
| EXPIRED_TOKEN | 401 surfaces as "session expired — run /signin". |
| Another /publish in flight (same project) | "supa.page: another /publish is already running here (pid=…, Xs ago). Wait or kill that process." Exit 2. |
| NETWORK_DOWN | curl returns 000 → "Could not reach <server>. Check your network or SUPA_PAGE_SERVER." |
| 500 from server | Surface the response body, audit-log with status=500. |
| Empty $ARGUMENTS | Ask for a message; if user blanks it, ship with empty string. |

## /rollback

| Mode | Expected |
|---|---|
| MISSING_CFG | Same as /publish. |
| NOT_AUTHED | Same as /publish. |
| EMPTY $ARGUMENTS | Use AskUserQuestion to render the recent snapshots; user picks one. |
| MALFORMED snapshot id | Local regex check rejects before API call. |
| Snapshot does not exist | 404 from server → "Snapshot not found. Run /list-publishes." |
| Snapshot exists but source/ corrupted | 404 (Phase 1.5 safety) → "Snapshot exists but its source/ is missing. Pick a different snapshot." |
| Another /publish or /rollback in flight | Lock rejection, same as /publish. |

## /visibility

| Mode | Expected |
|---|---|
| EMPTY $ARGUMENTS | AskUserQuestion with Public / Private options. |
| Bad value ("nope") | 400 from server; surface "visibility must be 'public' or 'private'." |
| Caller doesn't own the site (somehow synced wrong .supa-page.json) | 401 from /api/sites/:name/visibility → suggest /signin. |
| Network down | Standard 000 message. |

## /diff

| Mode | Expected |
|---|---|
| MISSING_CFG | Standard. |
| NOT_AUTHED | Standard. |
| Empty diff | "No changes — staging matches prod." |
| Many changes | Show all per-line (no truncation in v0.1.3). |

## /preview

| Mode | Expected |
|---|---|
| MISSING_CFG | Standard. (No /signin required — preview is auth-free.) |
| Browser open command missing | Print the URL anyway. |

## /list

| Mode | Expected |
|---|---|
| NOT_AUTHED | "Not signed in. Run /signin to authorize this machine." |
| Zero sites | "No sites yet. Run /new <name> to create your first." |
| Many sites (>20) | List them all (no pagination in v0.1.3). |

## /status

| Mode | Expected |
|---|---|
| MISSING_CFG | "Not in a supa.page site directory. Run /new <name> or cd into an existing site." |
| NOT_AUTHED | Show local config, mark "Not signed in — run /signin." |
| Server healthy | "Server: ok" |
| Server unreachable | "Server: unreachable (000)" with the actual status code if any. |

## /signin

| Mode | Expected |
|---|---|
| Already signed in | Overwrite session.json. No warning needed — re-running /signin is the recovery path. |
| User denies in browser | "access_denied" from token endpoint → "You denied the authorization. Run /signin again to retry." |
| Code expired (waited >15min) | "expired_token" → "Code expired. Run /signin again." |
| First-time signin (welcomed_at = null) | Prompt for workspace name, POST /api/welcome, then print success. |

## /signout

| Mode | Expected |
|---|---|
| Not signed in (no session.json) | "Not signed in." Exit 0. |
| BA /api/auth/sign-out returns non-2xx | Still delete the local session.json (we want the local sign-out to succeed even if the server rejected the bearer for some reason). |

## /domain-add

| Mode | Expected |
|---|---|
| EMPTY $ARGUMENTS | Ask for the domain. |
| Bad shape (no TLD, contains /, starts with -, >253 chars, https:// prefix) | Local regex rejects before API. Show the rule. |
| *.supa.page host | Local check rejects ("Cannot register a *.supa.page host"). |
| 409 (already claimed) | Surface. |
| Domain points at Cloudflare proxy | initial status comes back error_dns; user can /domain-recheck after disabling the proxy. |

## /domain-list

| Mode | Expected |
|---|---|
| No domains | "No custom domains registered. Use /domain-add to add one." |
| Mixed statuses | Render each with the right indicator (✓ ⏳ ⚠ – 🔒). |

## /domain-remove

| Mode | Expected |
|---|---|
| 404 (not bound to a site you own) | "Domain not registered, or not owned by you. Run /domain-list to confirm." |
| Bad shape | Local regex check rejects. |

## /domain-recheck

| Mode | Expected |
|---|---|
| dns_verified / active | "✓ <domain> is configured correctly." |
| pending_dns | "⏳ <domain> isn't resolving yet. DNS may still be propagating." |
| error_dns | "⚠ <domain> resolves to <observed>, but we expected <expected>. Check DNS records at your registrar." |

## How to run this matrix manually

```bash
# 1. Spin up a fresh dev server in one terminal
DB_PATH=":memory:" SITES_ROOT=/tmp/qa-sites bun run dev

# 2. In another terminal, install the plugin in dev mode and walk through
#    each command above. Confirm output matches expected for each row.

# 3. Specifically test the cross-platform footguns:
#    - On Linux: full pass.
#    - On macOS: confirm `mktemp` and `sed` calls don't error.
#    - On Windows WSL: install jq + curl, confirm hooks fire.

# 4. Audit log: tail ~/.claude/audit.log while running the matrix and
#    confirm one structured line lands per state-changing action.
```

## What's NOT covered automatically

These are documented gaps because the test surface lives across machines + accounts:

- **OAuth provider end-to-end** — DCR + auth-code + token exchange + MCP tool call. Verified manually via the SSE/MCP smoke script.
- **Real DNS / Caddy / Let's Encrypt** — verified on the Hetzner box by hand. No automated end-to-end.
- **Resend email delivery** — OTP emails must actually reach the inbox. Tested manually per release.

For automated coverage of these, a follow-up "end-to-end smoke harness" is queued for v0.1.4.
