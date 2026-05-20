---
description: Force a DNS re-check on a custom domain
argument-hint: <domain>
allowed-tools: mcp__plugin_supa-page-plugin_supa-page__recheck_domain, AskUserQuestion
model: sonnet
---

The user wants to nudge supa.page to re-verify a custom domain's DNS.

Get the domain from `$ARGUMENTS`. If empty, use AskUserQuestion (header "Domain", description: "The domain to re-check, e.g. www.example.com").

Call `mcp__plugin_supa-page-plugin_supa-page__recheck_domain` with `{domain}`. Surface the response: if it now resolves correctly, congratulate; if it still mismatches, show the expected vs actual records and remind the user to update at their registrar.
