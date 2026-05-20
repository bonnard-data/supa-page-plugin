---
title: "Work in progress"
date: 2026-05-21
published: false
excerpt: "Notes from a redesign-in-flight."
tags: [design, in-progress]
---

This post is a draft. It renders at `/posts/draft-post` only via the preview
channel (`?preview=<site>`).

It does **not** appear in `/posts`, RSS, sitemap, or any `post-feed` section.

To ship it: change `published` to `true` in the frontmatter, then run `/publish`.

## Why drafts work this way

Post-level draft state is the only content state that lives outside the
publish boundary. The rest of the site has one publish flag (`/publish`).
Posts let you author drafts in `source/` and only flip them live with this
single frontmatter switch.
