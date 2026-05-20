---
description: Create a new supa.page site and scaffold local files
argument-hint: <site-name>
allowed-tools: Bash, AskUserQuestion
model: sonnet
---

The user wants to create a new supa.page site.

If `$ARGUMENTS` is non-empty, use it as the site name. Otherwise use AskUserQuestion (header "Site name", description: "Lowercase kebab-case, 1-64 chars, e.g. `vibrant-otter`") to get one.

Then run:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/new.sh "<name>"
```

Present the output verbatim. Exit code handling:
- 0: success — site reserved on server + scaffolded to `./<name>/`.
- 2: session expired — suggest `/signin`.
- 64: invalid name (the script logs the rule) — ask the user for a valid name and retry.
- 1: name taken (409) or generic error — surface and ask for another name on 409.

After success, mention: "Now edit `./<name>/source/pages/index.json` with Claude — the PostToolUse sync hook keeps it in sync with the server. When ready, `/publish`."
