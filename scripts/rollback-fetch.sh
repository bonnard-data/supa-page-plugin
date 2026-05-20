#!/usr/bin/env bash
# /rollback (step 1) — fetch the list of publishes for the current site.
# Emits JSON on stdout; the skill body either picks $ARGUMENTS or asks the user.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1090
source "$HERE/../lib/api.sh"

supa::ensure_deps      || exit 1
supa::find_site_config || exit 1
supa::ensure_signed_in || {
  echo "Run /signin first, then /rollback again." >&2
  exit 2
}

RESP="$(supa::api GET "/api/publishes?site=$SUPA_SITE")"
http_status="$(echo "$RESP" | head -1)"
payload="$(echo "$RESP" | tail -n +2)"

case "$http_status" in
  2*) ;;
  401) echo "Session expired — run /signin." >&2; exit 2 ;;
  *)   echo "API error ($http_status): $payload" >&2; exit 1 ;;
esac

# Pretty list for the user, plus the raw JSON so the skill can build AskUserQuestion options.
echo "Recent publishes for $SUPA_SITE:"
echo "$payload" | jq -r '.publishes | (.[0:10] // .) | to_entries[] |
  "  [\(.key + 1)] \(.value.snapshot)\n      \(.value.timestamp)  \(.value.message // "(no message)")"'
echo
echo "=== JSON_BEGIN ==="
echo "$payload" | jq -c '{publishes: (.publishes | (.[0:10] // .) | map({snapshot, timestamp, message}))}'
echo "=== JSON_END ==="
