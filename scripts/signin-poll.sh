#!/usr/bin/env bash
# /signin (step 2) — poll the device token endpoint until the user authorizes.
# On success: writes ~/.config/supa-page/session.json, checks /api/me, and
# emits either a success line or a workspace-name prompt.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1090
source "$HERE/../lib/api.sh"

DEVICE_CODE="${1:-}"
SERVER="${SUPA_PAGE_SERVER:-https://supa.page}"
INTERVAL=5

if [ -z "$DEVICE_CODE" ]; then
  echo "signin-poll.sh: missing <device_code> arg." >&2
  exit 64
fi

DEADLINE=$(( $(date +%s) + 900 ))

while [ "$(date +%s)" -lt "$DEADLINE" ]; do
  RESP="$(curl -sS -X POST "$SERVER/api/auth/device/token" \
    -H "Content-Type: application/json" \
    -d "$(jq -cn --arg dc "$DEVICE_CODE" \
        '{grant_type:"urn:ietf:params:oauth:grant-type:device_code", device_code:$dc, client_id:"supa-page-plugin"}')")"
  err="$(echo "$RESP" | jq -r '.error // empty')"
  case "$err" in
    authorization_pending) sleep "$INTERVAL" ;;
    slow_down)             INTERVAL=$((INTERVAL+5)); sleep "$INTERVAL" ;;
    access_denied)         echo "You denied the authorization. Run /signin to retry." >&2; exit 3 ;;
    expired_token)         echo "Code expired (waited >15min). Run /signin again." >&2; exit 4 ;;
    "")                    break ;;
    *)                     echo "Unexpected: $err — $RESP" >&2; exit 5 ;;
  esac
done

token="$(echo "$RESP" | jq -r '.access_token // empty')"
if [ -z "$token" ]; then
  echo "Timed out waiting for browser authorization. Run /signin again." >&2
  exit 6
fi

SESS_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/supa-page"
mkdir -p "$SESS_DIR"
SESS_FILE="$SESS_DIR/session.json"
jq -cn --arg s "$SERVER" --arg t "$token" '{server:$s, session_token:$t}' > "$SESS_FILE"
chmod 600 "$SESS_FILE"

# /api/me to learn email + welcomed state
ME="$(curl -sS "$SERVER/api/me" -H "Authorization: Bearer $token")"
email="$(echo "$ME" | jq -r '.user.email')"
welcomed_at="$(echo "$ME" | jq -r '.user.welcomed_at // "null"')"
org_id="$(echo "$ME" | jq -r '.org_id // empty')"

supa::audit_log signin server="$SERVER" email="$email" || true

if [ "$welcomed_at" = "null" ] && [ -z "$org_id" ]; then
  # First-time signin: skill must ask the user for a workspace name then POST /api/welcome
  echo "NEEDS_WELCOME=1"
  echo "EMAIL=$email"
  echo "TOKEN=$token"
  echo "SERVER=$SERVER"
  exit 0
fi

echo "✓ Signed in as $email"
echo "  Run /list to see your sites."
