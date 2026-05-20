#!/usr/bin/env bash
# /domain-list — show all custom domains for the current site with status.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1090
source "$HERE/../lib/api.sh"

supa::ensure_deps      || exit 1
supa::find_site_config || exit 1
supa::ensure_signed_in || {
  echo "Run /signin first." >&2
  exit 2
}

RESP="$(supa::api GET "/api/domains?site=$SUPA_SITE")"
http_status="$(echo "$RESP" | head -1)"
payload="$(echo "$RESP" | tail -n +2)"

case "$http_status" in
  2*) ;;
  401) echo "Session expired — run /signin." >&2; exit 2 ;;
  *)   echo "API error ($http_status): $payload" >&2; exit 1 ;;
esac

count="$(echo "$payload" | jq '.domains | length')"
if [ "$count" = "0" ]; then
  echo "No custom domains registered. Use /domain-add to add one."
  exit 0
fi

echo "$payload" | jq -r '
  .domains[] |
  (if .password_protected then "🔒 " else "" end) as $lock |
  ({
    "active": "✓",
    "dns_verified": "⏳",
    "issuing_cert": "⏳",
    "pending_dns": "⏳",
    "error_dns": "⚠",
    "error_cert": "⚠",
    "disabled": "–"
  }[.status] // "?") as $icon |
  "\($icon) \($lock)\(.domain)\t(\(.status))\t\(.last_error // "")"
' | awk -F'\t' '{
  if (NF == 3 && $3 != "") {
    printf "%s %-32s %s\n    %s\n", $1, $2, $3, $4 = $3
  } else {
    printf "%s %-32s %s\n", $1, $2, $3
  }
}'

# Suggest a recheck for any non-active domains
non_active="$(echo "$payload" | jq '[.domains[] | select(.status != "active")] | length')"
if [ "$non_active" != "0" ]; then
  echo
  echo "Run /domain-recheck <domain> to force a DNS re-check."
fi
