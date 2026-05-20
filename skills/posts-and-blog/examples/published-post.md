---
title: "How we shipped v0.1.3 in three weeks"
date: 2026-05-20
published: true
excerpt: "A retro on the supa.page hard-cut release — auth refactor, MCP server, 15-section catalogue, 297 tests."
tags: [engineering, retros]
og_image: https://cdn.example.com/og/v0.1.3.png
---

Three weeks of focused work shipped v0.1.3 — a release big enough that it
arguably should have been v0.2. Here's what landed and what we cut.

## The token refactor

The single biggest change: dropping per-site sync tokens.

Pre-v0.1.3, every site carried a `sync_token` column. The plugin's
`.supa-page.json` stored it; every API call sent it as Bearer; the dashboard
displayed it. The result was that customers committed tokens to git by
accident every other week, and we spent an hour at a time rotating them.

The fix was structural: there's no token. Every CLI call reads the user's
Better Auth session bearer from `~/.config/supa-page/session.json` and sends
the site name in the request body. The server resolves "does this user own
this site?" via org membership. `.supa-page.json` is now `{ "site", "server" }`
and safe to commit.

## What got cut

- Native image hosting (deferred to v0.2 — we'll do it properly)
- Site templates (`/new --template saas` etc.)
- Site delete from the CLI (dashboard-only for now)

## What this skill demonstrates

This post itself is a published Markdown file under `source/posts/`. Its
`published: true` lets it appear in `/posts`, RSS, sitemap. Its `tags`
let a `post-feed` section filter to engineering content. Its `og_image`
shows up when the URL is shared on Twitter/Slack.
