---
description: Sign in to supa.page from this machine (browser device-flow)
allowed-tools: Bash, AskUserQuestion
model: sonnet
---

The user wants to sign in to their supa.page account. This uses the OAuth 2.0 Device Authorization Grant (RFC 8628) — same pattern as `gh auth login`, AWS CLI, Stripe CLI. The user authorizes the CLI from their browser, the CLI polls until the bearer is issued.

**Step 1: request a device code.**

!`bash ${CLAUDE_PLUGIN_ROOT}/scripts/signin-init.sh`

Show the user the verification URL and code from the output above. Extract the line `DEVICE_CODE=<value>` to use for polling.

**Step 2: poll for the bearer.** Run via the Bash tool (not `!` — this can take up to 15 minutes):

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/signin-poll.sh "<device_code>"
```

If the output starts with `✓ Signed in as ...`, you're done — present that to the user.

**Step 3 (first-time only): complete the welcome.** If the poll output contains `NEEDS_WELCOME=1`, the user has no workspace yet. Extract `EMAIL=...`, `TOKEN=...`, and `SERVER=...` from the output, then ask:

- question: "What should we call your workspace?"
- header: "Workspace"
- description: "Examples: your name, your company, your project — e.g. \"bigfoot\", \"acme\"."

Then run via the Bash tool:

```bash
SUPA_TOKEN="<token>" bash ${CLAUDE_PLUGIN_ROOT}/scripts/signin-welcome.sh "<workspace-name>" "<server>"
```

Present the welcome script's output verbatim.

**Failure cases (from signin-poll.sh):**
- Exit 3: user denied authorization in the browser — tell them and suggest re-running.
- Exit 4: code expired (>15 min) — tell them and suggest re-running.
- Exit 5/6: unexpected / timeout — surface the error.

**Note for returning users:** if they're already signed in, this command silently overwrites the local session. Running `/signin` is also the recovery path if `~/.config/supa-page/session.json` got corrupted.
