#!/usr/bin/env bash
# supa.page SessionStart hook
#
# Fires once when a Claude Code session begins. Calls /api/me to fetch the
# signed-in user's profile + sites + active org, then exports them into the
# session environment via $CLAUDE_ENV_FILE. Lets later commands (and the
# agent itself) know "who am I" and "what sites are available" without
# running /list explicitly.
#
# Silent no-op when:
#   - the user isn't signed in (no session.json)
#   - the server is unreachable (network down)
#   - jq or curl is missing
#
# We never block session start — exit 0 even on failure.
set -euo pipefail

# Best-effort: missing deps mean no context, but the session still works.
command -v curl >/dev/null 2>&1 || exit 0
command -v jq   >/dev/null 2>&1 || exit 0

SESSION_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/supa-page/session.json"
[ -f "$SESSION_FILE" ] || exit 0

SERVER="$(jq -r '.server // empty' "$SESSION_FILE" 2>/dev/null || echo '')"
TOKEN="$(jq -r '.session_token // empty' "$SESSION_FILE" 2>/dev/null || echo '')"
SERVER="${SERVER:-${SUPA_PAGE_SERVER:-https://supa.page}}"

[ -z "$TOKEN" ] && exit 0

# 3-second connect timeout — we never want to delay session boot.
RESP="$(curl --max-time 3 -sS \
  -H "Authorization: Bearer $TOKEN" \
  "$SERVER/api/me" 2>/dev/null || echo '')"
[ -z "$RESP" ] && exit 0

EMAIL="$(echo "$RESP"   | jq -r '.user.email // empty' 2>/dev/null || echo '')"
ORG_ID="$(echo "$RESP"  | jq -r '.org_id // empty'     2>/dev/null || echo '')"
SITES="$(echo "$RESP"   | jq -r '.sites[].name'        2>/dev/null | tr '\n' ' ' | sed 's/ *$//' || echo '')"
SITE_COUNT="$(echo "$RESP" | jq -r '.sites | length // 0' 2>/dev/null || echo 0)"

if [ -n "${CLAUDE_ENV_FILE:-}" ] && [ -n "$EMAIL" ]; then
  {
    echo "export SUPA_PAGE_USER_EMAIL=$(printf %q "$EMAIL")"
    [ -n "$ORG_ID" ] && echo "export SUPA_PAGE_ORG_ID=$(printf %q "$ORG_ID")"
    [ -n "$SITES" ]  && echo "export SUPA_PAGE_SITES=$(printf %q "$SITES")"
    echo "export SUPA_PAGE_SERVER=$(printf %q "$SERVER")"
  } >> "$CLAUDE_ENV_FILE"
fi

# Surface a one-line orientation message in the session transcript.
if [ -n "$EMAIL" ]; then
  echo "supa.page: signed in as $EMAIL · $SITE_COUNT site(s) · server=$SERVER"
fi

exit 0
