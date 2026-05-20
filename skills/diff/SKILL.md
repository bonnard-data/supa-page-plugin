---
description: Show changes between staging (source) and the current publish
argument-hint: [site]
allowed-tools: mcp__plugin_supa-page-plugin_supa-page__diff_site, mcp__plugin_supa-page-plugin_supa-page__list_sites, AskUserQuestion
model: haiku
---

The user wants the diff between staging and prod for a site.

If `$ARGUMENTS` is a site name, use it. Otherwise call `list_sites` and pick from context or ask via AskUserQuestion.

Call `mcp__plugin_supa-page-plugin_supa-page__diff_site` with the site name. Render the result as:

```
+ <added paths>
~ <modified paths>
- <deleted paths>
```

If all three arrays are empty, say "No changes — staging matches prod."
