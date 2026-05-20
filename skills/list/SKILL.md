---
description: List the supa.page sites the signed-in user owns
allowed-tools: mcp__plugin_supa-page-plugin_supa-page__list_sites
model: haiku
---

The user wants to see their supa.page sites.

Call `mcp__plugin_supa-page-plugin_supa-page__list_sites` (no arguments) and present the result as a clean table: name, visibility, URL (`https://<name>.supa.page`).

If the tool errors with an auth message, tell the user to run `/mcp` and authenticate. If the list is empty, suggest `/new <name>` to create the first one.
