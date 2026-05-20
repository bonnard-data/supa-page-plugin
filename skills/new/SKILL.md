---
description: Create a new supa.page site with a default page + initial publish
argument-hint: <name>
allowed-tools: mcp__plugin_supa-page-plugin_supa-page__create_site, AskUserQuestion
model: sonnet
---

The user wants to create a new supa.page site.

Get the name from `$ARGUMENTS`. If empty, use AskUserQuestion (header "Site name", description: "Lowercase kebab-case, 1-64 chars, e.g. `acme-launch`").

Call `mcp__plugin_supa-page-plugin_supa-page__create_site` with `{name}` (omit `org` unless the user is in multiple orgs and specified one). Surface the returned preview + live URLs.

Then tell the user:
- "Use `sync_files` (via me) to author your site — `site.json` for theme, `pages/<slug>.json` for pages, `posts/<slug>.md` for blog posts."
- "Run `/publish <name>` when you want to roll out changes, `/visibility <name> public` to make it world-readable."

If the tool errors with "already taken", ask for another name. If it errors with "no organization", direct the user to sign up via the dashboard first.
