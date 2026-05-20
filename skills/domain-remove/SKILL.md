---
description: Unregister a custom domain from a site (DNS at registrar is untouched)
argument-hint: <domain>
allowed-tools: mcp__plugin_supa-page-plugin_supa-page__remove_domain, AskUserQuestion
model: sonnet
disable-model-invocation: true
---

The user wants to detach a custom domain from a site. `disable-model-invocation: true` — destructive; a human always confirms.

Get the domain from `$ARGUMENTS`. If empty, use AskUserQuestion (header "Domain to remove", description: "The domain to unregister, e.g. www.example.com").

Call `mcp__plugin_supa-page-plugin_supa-page__remove_domain` with `{domain}`. Confirm the unbind and remind the user this does NOT update DNS at their registrar — they may still want to delete the CNAME/A record there.
