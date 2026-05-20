#!/usr/bin/env bash
# /diff — show changes between staging (source/) and the current publish.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1090
source "$HERE/../lib/api.sh"

supa::ensure_deps      || exit 1
supa::find_site_config || exit 1
supa::ensure_signed_in || {
  echo "Run /signin first, then /diff again." >&2
  exit 2
}

RESP="$(supa::api GET "/api/diff?site=$SUPA_SITE")"
http_status="$(echo "$RESP" | head -1)"
payload="$(echo "$RESP" | tail -n +2)"

case "$http_status" in
  2*) ;;
  401) echo "Session expired — run /signin." >&2; exit 2 ;;
  *)   echo "API error ($http_status): $payload" >&2; exit 1 ;;
esac

added="$(echo "$payload" | jq '.added | length')"
modified="$(echo "$payload" | jq '.modified | length')"
deleted="$(echo "$payload" | jq '.deleted | length')"
total=$((added + modified + deleted))

if [ "$total" = "0" ]; then
  echo "No changes — staging matches prod."
  exit 0
fi

echo "Changes vs prod:"
echo "$payload" | jq -r '.added[]?    | "  + \(.)"'
echo "$payload" | jq -r '.modified[]? | "  ~ \(.)"'
echo "$payload" | jq -r '.deleted[]?  | "  - \(.)"'
echo
echo "  added: $added  modified: $modified  deleted: $deleted"
