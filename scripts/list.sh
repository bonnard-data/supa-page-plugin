#!/usr/bin/env bash
# /list — show all sites owned by the signed-in user.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1090
source "$HERE/../lib/api.sh"

supa::ensure_deps || exit 1
supa::ensure_signed_in || {
  echo "Not signed in. Run /signin to authorize this machine." >&2
  exit 2
}

RESP="$(supa::api GET /api/me)"
http_status="$(echo "$RESP" | head -1)"
payload="$(echo "$RESP" | tail -n +2)"

case "$http_status" in
  2*) ;;
  401)
    echo "Session expired — run /signin." >&2
    exit 2
    ;;
  *)
    echo "API error ($http_status): $payload" >&2
    exit 1
    ;;
esac

email="$(echo "$payload" | jq -r '.user.email')"
count="$(echo "$payload" | jq '.sites | length')"

echo "Signed in as $email"
echo

if [ "$count" = "0" ]; then
  echo "No sites yet. Run /new <name> to create your first."
  exit 0
fi

echo "$payload" | jq -r '.sites[] | "\(.name)\t\(.visibility)\thttps://\(.name).supa.page"' \
  | awk -F'\t' '{ printf "  %-24s (%-7s)  %s\n", $1, $2, $3 }'
