---
description: Force a DNS re-check on a custom domain
argument-hint: <domain>
allowed-tools: Bash, AskUserQuestion
model: haiku
---

Force an immediate DNS re-check on a domain.

If `$ARGUMENTS` is empty, first show the current domains:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/domain-list.sh
```

Then use AskUserQuestion to pick one (header "Re-check which?"). Otherwise pass `$ARGUMENTS` directly.

Then run:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/domain-recheck.sh "<domain>"
```

Present the output verbatim. Icons: `✓` ok, `⏳` propagating, `⚠` resolves elsewhere.
