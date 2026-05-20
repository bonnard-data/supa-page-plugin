---
description: Sign in to supa.page (handled by Claude Code's MCP OAuth flow)
allowed-tools: mcp__plugin_supa-page-plugin_supa-page__whoami
model: haiku
---

As of v0.2.0, sign-in is handled by Claude Code's MCP OAuth flow — there's no separate `/signin` device dance to run.

To check current auth state, call `mcp__plugin_supa-page-plugin_supa-page__whoami`. If it succeeds, present the user's identity ("Signed in as `<email>` · org `<slug>`") and stop.

If `whoami` returns an auth error, tell the user:

> Open `/mcp`, select **plugin:supa-page-plugin:supa-page**, and choose **Authenticate**. Your browser will open for the OAuth consent step. Once approved, all supa.page MCP tools become available automatically.

First-time users will be bounced through the supa.page dashboard's email-OTP / GitHub / Google sign-in and a one-time workspace-name step before the consent screen.
