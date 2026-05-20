#!/usr/bin/env bash
# /signin (step 1) — request a device code from the server, render the prompt.
# Outputs the verification URL + user code on stdout, plus a "DEVICE_CODE=<...>"
# line that the skill body extracts to pass into signin-poll.sh.
set -euo pipefail

SERVER="${SUPA_PAGE_SERVER:-https://supa.page}"

RESP="$(curl -sS -X POST "$SERVER/api/auth/device/code" \
  -H "Content-Type: application/json" \
  -d '{"client_id":"supa-page-plugin"}')"

if ! echo "$RESP" | jq -e .device_code >/dev/null 2>&1; then
  echo "supa.page: failed to request a device code from $SERVER" >&2
  echo "$RESP" >&2
  exit 1
fi

device_code="$(echo "$RESP" | jq -r .device_code)"
user_code="$(echo "$RESP" | jq -r .user_code)"
verification_uri="$(echo "$RESP" | jq -r .verification_uri)"
verification_uri_complete="$(echo "$RESP" | jq -r .verification_uri_complete)"
interval="$(echo "$RESP" | jq -r .interval)"
expires_in="$(echo "$RESP" | jq -r .expires_in)"

# Best-effort browser open
case "$(uname)" in
  Darwin) open "$verification_uri_complete" 2>/dev/null || true ;;
  Linux)  xdg-open "$verification_uri_complete" 2>/dev/null || true ;;
  *)      start "$verification_uri_complete" 2>/dev/null || true ;;
esac

cat <<EOF
To sign in, visit:
  $verification_uri

And enter this code:
  $user_code

(I tried to open $verification_uri_complete in your browser — the code is pre-filled.)

SERVER=$SERVER
DEVICE_CODE=$device_code
INTERVAL=$interval
EXPIRES_IN=$expires_in
EOF
