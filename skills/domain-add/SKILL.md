---
description: Register a custom domain for a site
argument-hint: [site] <domain>
allowed-tools: mcp__plugin_supa-page-plugin_supa-page__add_domain, mcp__plugin_supa-page-plugin_supa-page__list_sites, AskUserQuestion
model: sonnet
---

The user wants to bind a custom domain to a site.

Parse `$ARGUMENTS`. The domain is required (apex like `example.com` or subdomain like `www.example.com`). The site is optional — resolve from context or `list_sites` + AskUserQuestion if missing.

Reject obvious-bad shapes locally before calling the tool: drop any `https://` prefix, reject `*.supa.page` hosts (reserved), reject inputs that don't match `^([a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z]{2,}$`.

Call `mcp__plugin_supa-page-plugin_supa-page__add_domain` with `{site, domain}`. Present the returned DNS instructions (apex → A record; subdomain → CNAME to `routing.supa.page`). Tell the user HTTPS issues automatically within ~5 minutes of DNS propagation and they can run `/domain-list <site>` to check status.
