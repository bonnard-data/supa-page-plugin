---
description: Publish staging to production (snapshots source/ → flips current.json)
argument-hint: [message]
allowed-tools: Bash, AskUserQuestion
model: sonnet
---

The user wants to publish the current supa.page site's staging state to production.

If `$ARGUMENTS` is non-empty, use it directly as the publish message. Otherwise use AskUserQuestion (header "Publish message", e.g. "v2 launch", short like a commit message) to gather a message. If the user blanks it, ship with an empty string.

Then run:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/publish.sh "<message>"
```

Present the script output verbatim.

Exit-code handling:
- 0: success — done.
- 2: session expired — suggest `/signin`.
- 3: another /publish is in flight from this dir — surface the message; ask the user to wait or kill the other process.
- 64: empty message (you forgot to pass one; re-prompt and retry).
- non-zero other: surface the error and stop.

**Important context for the user**: `/publish` snapshots whatever is currently on the server (synced via the PostToolUse hook). If edits haven't synced yet, they won't be in the snapshot — confirm with `/diff` first if unsure. New sites are `visibility=private`; toggle with `/visibility public`.
