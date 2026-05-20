#!/usr/bin/env bash
# supa.page sync hook (v0.1.3)
#
# Fires on PostToolUse for Write|Edit|MultiEdit. Walks up from the edited file
# looking for .supa-page.json. If found, and the file is inside the site's
# source/ tree, POSTs it to /api/sync using the user's BA session bearer from
# ~/.config/supa-page/session.json. Otherwise exits silently.
#
# v0.1.3 changed the auth model:
#   - Bearer is the user's session token (~/.config/supa-page/session.json),
#     not a per-site sync_token in .supa-page.json
#   - Request body carries {site, files} — server resolves "which site does
#     this caller own?" via BA membership
set -euo pipefail

INPUT="$(cat)"

FILE_PATH="$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty')"
[ -z "$FILE_PATH" ] && exit 0
[ ! -f "$FILE_PATH" ] && exit 0

# Walk up looking for .supa-page.json (the site marker)
DIR="$(cd "$(dirname "$FILE_PATH")" && pwd)"
CONFIG=""
SITE_ROOT=""
while [ "$DIR" != "/" ] && [ -n "$DIR" ]; do
  if [ -f "$DIR/.supa-page.json" ]; then
    CONFIG="$DIR/.supa-page.json"
    SITE_ROOT="$DIR"
    break
  fi
  DIR="$(dirname "$DIR")"
done

# Not inside a supa.page site — silent no-op
[ -z "$CONFIG" ] && exit 0

SOURCE_ROOT="$SITE_ROOT/source"

# Only sync files inside source/
case "$FILE_PATH" in
  "$SOURCE_ROOT"/*) REL_PATH="${FILE_PATH#$SOURCE_ROOT/}" ;;
  *) exit 0 ;;
esac

SITE="$(jq -r '.site' "$CONFIG")"
SERVER="$(jq -r '.server' "$CONFIG")"

# Honour the per-project plugin state file. `.claude/supa-page-plugin.local.md`
# carries YAML frontmatter; if `auto_sync: false` is set, this hook stays
# silent and the customer triggers /sync manually.
STATE_FILE="$SITE_ROOT/.claude/supa-page-plugin.local.md"
if [ -f "$STATE_FILE" ]; then
  if sed -n '/^---$/,/^---$/{ /^---$/d; p; }' "$STATE_FILE" 2>/dev/null \
      | grep -qE '^auto_sync:\s*false\s*$'; then
    # auto_sync explicitly disabled — silent no-op (the user can grep this
    # behaviour from .claude/supa-page-plugin.local.md).
    exit 0
  fi
fi

# Locate the user's session token (set by /signin)
SESSION_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/supa-page/session.json"
if [ ! -f "$SESSION_FILE" ]; then
  echo "supa.page sync: not signed in — run /signin to authorize." >&2
  exit 0
fi
TOKEN="$(jq -r '.session_token' "$SESSION_FILE")"
if [ -z "$TOKEN" ] || [ "$TOKEN" = "null" ]; then
  echo "supa.page sync: session file is malformed — run /signin again." >&2
  exit 0
fi

# Embed file content as a JSON string with jq -Rs (utf8 only — binary files
# get mangled here; native asset hosting is on the roadmap for v0.2).
CONTENT="$(jq -Rs . < "$FILE_PATH")"
PAYLOAD="$(jq -cn --arg s "$SITE" --arg p "$REL_PATH" --argjson c "$CONTENT" \
  '{site: $s, files: [{path: $p, content: $c}]}')"

HTTP_STATUS=$(curl -sS -o /tmp/supa-sync-resp.$$ -w '%{http_code}' \
  -X POST "$SERVER/api/sync" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD" || echo "000")

BODY="$(cat /tmp/supa-sync-resp.$$ 2>/dev/null || echo '')"
rm -f /tmp/supa-sync-resp.$$

case "$HTTP_STATUS" in
  200)
    echo "supa.page · synced $SITE/$REL_PATH"
    ;;
  401)
    echo "supa.page sync: session rejected (401) — run /signin to re-authorize." >&2
    ;;
  403)
    echo "supa.page sync: not authorized for $SITE (403). Check the site name in .supa-page.json." >&2
    ;;
  413)
    echo "supa.page sync: $SITE/$REL_PATH is too large (>1MB). Skipping." >&2
    ;;
  000)
    echo "supa.page sync: could not reach $SERVER. Check your network or SUPA_PAGE_SERVER." >&2
    ;;
  *)
    echo "supa.page sync FAILED ($HTTP_STATUS) for $SITE/$REL_PATH: $BODY" >&2
    ;;
esac

# Non-blocking: exit 0 so Claude doesn't treat a sync hiccup as a tool failure.
exit 0
