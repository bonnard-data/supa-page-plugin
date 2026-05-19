#!/usr/bin/env bash
# supa.page sync hook
#
# Fires on PostToolUse for Write|Edit|MultiEdit. Walks up from the edited file
# looking for .supa-page.json. If found, and the file is inside the site's
# source/ tree, POSTs it to /api/sync. Otherwise exits silently.
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
TOKEN="$(jq -r '.token' "$CONFIG")"

# Embed file content as a JSON string with jq -Rs
CONTENT="$(jq -Rs . < "$FILE_PATH")"
PAYLOAD="$(jq -cn --arg p "$REL_PATH" --argjson c "$CONTENT" \
  '{files: [{path: $p, content: $c}]}')"

HTTP_STATUS=$(curl -sS -o /tmp/supa-sync-resp.$$ -w '%{http_code}' \
  -X POST "$SERVER/api/sync" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD" || echo "000")

BODY="$(cat /tmp/supa-sync-resp.$$ 2>/dev/null || echo '')"
rm -f /tmp/supa-sync-resp.$$

if [ "$HTTP_STATUS" = "200" ]; then
  echo "supa.page · synced $SITE/$REL_PATH"
  exit 0
else
  echo "supa.page sync FAILED ($HTTP_STATUS) for $SITE/$REL_PATH: $BODY" >&2
  # Non-blocking: exit 0 so Claude doesn't see this as a tool failure.
  # The stderr message still shows up in the transcript.
  exit 0
fi
