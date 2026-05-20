---
description: Unregister a custom domain from the current site
argument-hint: <domain>
allowed-tools: Bash, AskUserQuestion
model: sonnet
disable-model-invocation: true
---

The user wants to remove a custom domain. `disable-model-invocation` is set — only a direct invocation can reach this; subagents can't remove a domain.

If `$ARGUMENTS` is empty, first show the current domains by running:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/domain-list.sh
```

Then use AskUserQuestion to confirm which domain to remove (header "Remove which?"). Otherwise pass `$ARGUMENTS` directly.

Then run:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/domain-remove.sh "<domain>"
```

Present the output verbatim. On 404 ("not owned"), suggest `/domain-list` to confirm the spelling.
