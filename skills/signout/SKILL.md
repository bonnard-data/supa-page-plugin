---
description: Sign out of supa.page (handled by Claude Code's MCP dialog)
model: haiku
---

As of v0.2.0, sign-out is handled by Claude Code's MCP machinery — there's no separate token file to clear.

Tell the user:

> Open `/mcp`, select **plugin:supa-page-plugin:supa-page**, and choose **Clear authentication**. The cached OAuth token is dropped; the next MCP tool call will trigger a fresh sign-in.

If they want to fully revoke the token server-side (so it can't be replayed from a stolen `~/.claude/...` file), they can also sign out from `https://app.supa.page` — that revokes the underlying Better Auth session, which cascades to all OAuth tokens issued under it.
