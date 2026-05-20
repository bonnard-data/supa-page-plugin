---
description: Set site visibility — public lets anyone view it, private gates to org members
argument-hint: [public|private]
allowed-tools: Bash, AskUserQuestion
model: sonnet
---

The user wants to change the current site's visibility.

If `$ARGUMENTS` is `public` or `private`, use it directly. Otherwise use AskUserQuestion:

- question: "Who should be able to view <site>.supa.page?"
- header: "Visibility"
- options:
  - **Public** — Anyone can view
  - **Private** — Only signed-in org members can view

Then run:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/visibility.sh "<value>"
```

Present the output verbatim.

Note: visibility is a long-lived site property, separate from publishing. No need to re-publish after toggling. The preview URL (`<server>/?preview=<site>`) is always reachable by site owners regardless of visibility.
