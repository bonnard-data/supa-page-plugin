#!/usr/bin/env bash
# /signout — revoke the BA session server-side, delete the local session file.
# Invoked by skills/signout/SKILL.md via the `!` prefix.
set -euo pipefail

SESS_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/supa-page/session.json"

if [ ! -f "$SESS_FILE" ]; then
  echo "Not signed in."
  exit 0
fi

server="$(jq -r '.server // empty' "$SESS_FILE" 2>/dev/null || echo '')"
token="$(jq -r '.session_token // empty' "$SESS_FILE" 2>/dev/null || echo '')"

if [ -z "$server" ] || [ -z "$token" ]; then
  echo "Session file malformed at $SESS_FILE — deleting locally."
  rm -f "$SESS_FILE"
  exit 0
fi

# Best-effort revoke. Local sign-out succeeds even if server rejects the bearer.
curl -sS -o /dev/null -X POST "$server/api/auth/sign-out" \
  -H "Authorization: Bearer $token" 2>/dev/null || true

rm -f "$SESS_FILE"

# Audit log (best-effort; never fails)
HERE="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1090
source "$HERE/../lib/api.sh"
supa::audit_log signout server="$server" || true

echo "✓ Signed out."
