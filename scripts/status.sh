#!/usr/bin/env bash
# /status — show the current site's config, sign-in state, and a server health probe.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1090
source "$HERE/../lib/api.sh"

supa::ensure_deps || exit 1

if ! supa::find_site_config 2>/dev/null; then
  echo "Not in a supa.page site directory. Run /new <name> to create one, or cd into an existing site."
  exit 0
fi

echo "Site:    $SUPA_SITE"
echo "Server:  $SUPA_SERVER"
echo "Preview: $SUPA_SERVER/?preview=$SUPA_SITE"
echo "Live:    $SUPA_SITE.supa.page   (if visibility=public)"

if supa::ensure_signed_in 2>/dev/null; then
  RESP="$(supa::api GET /api/me)"
  http_status="$(echo "$RESP" | head -1)"
  payload="$(echo "$RESP" | tail -n +2)"
  if [[ "$http_status" =~ ^2 ]]; then
    email="$(echo "$payload" | jq -r '.user.email')"
    echo "Signed in as: $email"
  else
    echo "Signed in: (session rejected by server, run /signin)"
  fi
else
  echo "Signed in: no — run /signin"
fi

server_code="$(curl -sf -o /dev/null -w '%{http_code}' "$SUPA_SERVER/health" 2>/dev/null || echo '000')"
if [ "$server_code" = "200" ]; then
  echo "Server:  ok"
else
  echo "Server:  unreachable ($server_code)"
fi
