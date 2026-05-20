#!/usr/bin/env bash
# supa.page Stop hook
#
# Fires when Claude is about to declare the task done. Checks whether the
# session edited any files inside a tracked supa.page site dir AND the
# server thinks production is out of sync (per /api/diff).
#
# If yes, emits a soft nudge to /publish — but does NOT block (exit 0).
# Customers should always be free to leave the session with un-published
# staging edits.
#
# Cheap-to-fail by design: any error in the hook is a silent no-op.
set -euo pipefail

command -v jq   >/dev/null 2>&1 || exit 0
command -v curl >/dev/null 2>&1 || exit 0

INPUT="$(cat 2>/dev/null || echo '{}')"
CWD="$(printf '%s' "$INPUT" | jq -r '.cwd // empty' 2>/dev/null || pwd)"
[ -z "$CWD" ] && CWD="$(pwd)"

# Find the nearest .supa-page.json from cwd.
DIR="$CWD"
while [ -n "$DIR" ] && [ "$DIR" != "/" ]; do
  [ -f "$DIR/.supa-page.json" ] && break
  DIR="$(dirname "$DIR")"
done
[ -z "$DIR" ] || [ ! -f "$DIR/.supa-page.json" ] && exit 0

SITE="$(jq -r '.site' "$DIR/.supa-page.json" 2>/dev/null || echo '')"
SERVER="$(jq -r '.server' "$DIR/.supa-page.json" 2>/dev/null || echo '')"
SERVER="${SERVER:-${SUPA_PAGE_SERVER:-https://supa.page}}"
[ -z "$SITE" ] || [ "$SITE" = "null" ] && exit 0

# Need a session token to ask /api/diff.
SESSION_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/supa-page/session.json"
[ -f "$SESSION_FILE" ] || exit 0
TOKEN="$(jq -r '.session_token // empty' "$SESSION_FILE" 2>/dev/null || echo '')"
[ -z "$TOKEN" ] && exit 0

# Hit /api/diff?site=<name>. 3-second cap so a flaky network never blocks Stop.
RESP="$(curl --max-time 3 -sS \
  -H "Authorization: Bearer $TOKEN" \
  "$SERVER/api/diff?site=$SITE" 2>/dev/null || echo '')"
[ -z "$RESP" ] && exit 0

# Count changed files across all three buckets.
COUNT="$(printf '%s' "$RESP" | jq -r '((.added // []) + (.modified // []) + (.deleted // [])) | length' 2>/dev/null || echo 0)"
[ "$COUNT" -gt 0 ] 2>/dev/null || exit 0

# Soft nudge. stderr is shown to Claude; she's free to either run /publish
# or end the turn after telling the user it's intentionally unpublished.
echo "supa.page: $COUNT staged change(s) in '$SITE' aren't published yet. Run /publish to push them live, or leave them staged on purpose." >&2

exit 0
