---
description: Register a custom domain (apex or subdomain) for the current site
argument-hint: <domain>
allowed-tools: Bash, AskUserQuestion
model: sonnet
---

The user wants to register a custom domain.

If `$ARGUMENTS` is empty, use AskUserQuestion to get the domain shape (header "Domain", e.g. "www.example.com or example.com"). Otherwise pass `$ARGUMENTS` directly.

Then run:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/domain-add.sh "<domain>"
```

Present the script's output verbatim. If exit code is 64 (validation error), surface the error and ask again. If 409, the domain is taken — ask the user if they want to try another. If 401, suggest `/signin`.

After a successful add, remind the user to run `/domain-list` after DNS propagates (~5 min) to confirm the cert issued.
