---
description: Roll prod back to a previous published snapshot
argument-hint: [snapshot-id]
allowed-tools: Bash, AskUserQuestion
model: sonnet
disable-model-invocation: true
---

The user wants to roll back the current site to a previous publish.

`disable-model-invocation: true` — subagents and loops can't invoke this. A human always confirms.

First, fetch the publish list:

!`bash ${CLAUDE_PLUGIN_ROOT}/scripts/rollback-fetch.sh`

The output includes a human-readable list of recent publishes and a JSON block between `=== JSON_BEGIN ===` and `=== JSON_END ===` containing `{publishes: [{snapshot, timestamp, message}]}`.

**Picking the snapshot:**

- If `$ARGUMENTS` matches `^\d{4}-\d{2}-\d{2}T\d{2}-\d{2}-\d{2}\.\d{3}Z(-[0-9a-f]{8})?$`, use it directly.
- Otherwise use AskUserQuestion with one option per publish from the JSON block. Each option's label is the timestamp formatted nicely (e.g. "2026-05-18 15:30 UTC"), description is the publish message.

Then run:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/rollback-act.sh "<snapshot>"
```

Present the output verbatim. On 404, the snapshot id either is malformed, doesn't exist, or its `source/` directory has been deleted — show the list again and ask for another.

Note: rollback flips the "current" pointer only. It does NOT touch `source/` — unpublished staging edits remain intact.
