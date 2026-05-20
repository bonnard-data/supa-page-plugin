---
description: List custom domains bound to a site with DNS + cert status
argument-hint: [site]
allowed-tools: mcp__plugin_supa-page-plugin_supa-page__list_domains, mcp__plugin_supa-page-plugin_supa-page__list_sites, AskUserQuestion
model: haiku
---

The user wants the custom-domain list for a site.

Resolve the site name from `$ARGUMENTS`, conversation context, or `list_sites` + AskUserQuestion.

Call `mcp__plugin_supa-page-plugin_supa-page__list_domains` with `{site}` and render each domain with its status:

- `ok` → ✓ live
- `pending` → ⏳ awaiting DNS / cert
- `error_dns` → ⚠ DNS mismatch (suggest `/domain-recheck <domain>` after fixing)
- `error_cert` → ✗ cert provisioning failed

If the list is empty: "No custom domains for `<site>`. Add one with `/domain-add <site> <domain>`."
