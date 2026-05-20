---
description: Toggle a site between public and private
argument-hint: [site] public|private
allowed-tools: mcp__plugin_supa-page-plugin_supa-page__set_visibility, mcp__plugin_supa-page-plugin_supa-page__list_sites, AskUserQuestion
model: sonnet
---

The user wants to change a site's visibility.

Parse `$ARGUMENTS`: it may be `<site> <public|private>`, just `<public|private>`, or empty.

Resolve the site name (use the explicit one, else pick from context, else `list_sites` + AskUserQuestion).

Resolve the visibility value (`public` or `private`). If neither was passed, use AskUserQuestion with two options (Public, Private) and the implications: public = anyone with the URL can view, private = only org members.

Call `mcp__plugin_supa-page-plugin_supa-page__set_visibility` with `{site, visibility}`. Confirm the change and (for public) show the live URL `https://<site>.supa.page`.
