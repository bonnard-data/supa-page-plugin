---
description: Show changes between drafts (staging) and main (live)
argument-hint: [site]
allowed-tools: mcp__plugin_supa-page-plugin_supa-page__diff_site, mcp__plugin_supa-page-plugin_supa-page__list_sites, AskUserQuestion
model: haiku
---

The user wants to see what's changed in their drafts versus what's currently live.

If `$ARGUMENTS` is a site name, use it. Otherwise call `list_sites` and pick from context or ask via AskUserQuestion.

Call `mcp__plugin_supa-page-plugin_supa-page__diff_site` with the site name. The response shape is:

```
{
  pages: { added: string[], modified: string[], deleted: string[] },
  posts: { added: string[], modified: string[], deleted: string[] },
  site_config: "unchanged" | "modified"
}
```

Render it grouped by content type. Within each group:

```
+ <added slugs>
~ <modified slugs>
- <deleted slugs>
```

If every array is empty and `site_config` is `"unchanged"`, say "No draft changes — main is up to date."

A non-empty diff means there's uncommitted draft work. Run `/publish` to promote drafts to main (and update `<site>.supa.page` immediately), or `/discard-changes` to throw the drafts away.
