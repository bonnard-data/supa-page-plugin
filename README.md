# supa-page-plugin

The official [Claude Code](https://claude.com/claude-code) plugin for [supa.page](https://supa.page) — build and deploy marketing sites from your terminal.

## Install

```
/plugin install supa-page-plugin@bonnard-data
```

After installing, restart Claude Code to pick up the new commands.

## What it does

Lets you author and deploy hosted marketing sites by editing JSON + Markdown files in your repo. Everything happens via slash commands; no browser dashboard required for day-to-day work.

## Commands

| Command | What it does |
|---|---|
| `/signin` | Sign in via OAuth device flow (email code, GitHub, or Google) |
| `/signout` | Clear local session |
| `/list` | List all sites you own |
| `/new <name>` | Create a new site bound to your account |
| `/publish` | Atomic publish: snapshot the working tree, swap `current.json` |
| `/rollback <snapshot>` | Revert to a previous published version |
| `/diff` | Show changes between working tree and current published version |
| `/preview` | Get the preview URL for the working tree |
| `/status` | Show site health, current version, recent publishes |
| `/domain-add <domain>` | Attach a custom domain (apex or subdomain) |
| `/domain-list` | List custom domains with DNS-verification status |
| `/domain-remove <domain>` | Detach a custom domain |
| `/domain-recheck <domain>` | Force a DNS re-check |

## How auth works

Sign-in uses the **OAuth 2.0 Device Authorization Grant** (RFC 8628) — the same pattern as `gh auth login`, `aws sso`, Stripe CLI, etc. The plugin prints a code and a URL. You open the URL in any browser, sign in (email OTP, GitHub, or Google), enter the code, and the plugin gets a bearer token. The same token works for both CLI and the web dashboard.

## How publishing works

Each site has a JSON structure on disk:

```
my-site/
  source/
    site.json          ← theme + chrome
    pages/
      index.json       ← page sections
      about.json
    components/        ← optional custom Lit components
```

Edit files normally. The plugin's `PostToolUse` hook auto-syncs changes to the preview channel. Run `/publish` when you're ready to flip the live version.

## Source

Plugin source lives in this repo. Backend source is separate and private. File issues here for plugin bugs; for platform-level issues, contact support via the supa.page dashboard.

## License

MIT
