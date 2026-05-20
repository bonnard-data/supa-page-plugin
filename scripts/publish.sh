#!/usr/bin/env bash
# /publish [message] — snapshot source/ → publishes/<id>/source/, flip current.json.
#
# Exit codes (consumed by the skill):
#   0  — success
#   2  — auth needed
#   3  — running another /publish (lock contention)
#   64 — empty message and we need the skill to ask the user
#   1  — generic error
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1090
source "$HERE/../lib/api.sh"

MESSAGE="${*:-}"

supa::ensure_deps      || exit 1
supa::find_site_config || exit 1
supa::ensure_signed_in || {
  echo "Run /signin first, then /publish again." >&2
  exit 2
}

# The empty-message case is the one place we hand control back to the skill so it
# can ask the user. The skill re-invokes us with the message as $1..$N.
if [ -z "$MESSAGE" ]; then
  echo "publish.sh: empty message — skill should prompt the user and re-invoke." >&2
  exit 64
fi

if ! supa::acquire_lock /publish; then
  exit 3
fi
trap 'supa::release_lock' EXIT

BODY="$(jq -cn --arg s "$SUPA_SITE" --arg m "$MESSAGE" '{site: $s, message: $m}')"
RESP="$(supa::api POST /api/publish "$BODY")"
http_status="$(echo "$RESP" | head -1)"
payload="$(echo "$RESP" | tail -n +2)"

case "$http_status" in
  2*)
    snap="$(echo "$payload" | jq -r '.snapshot')"
    supa::audit_log publish site="$SUPA_SITE" snapshot="$snap" message="$MESSAGE" status=200
    echo "✓ Published — $MESSAGE"
    echo "  snapshot: $snap"
    echo "  preview:  $SUPA_SERVER/?preview=$SUPA_SITE"
    echo "  live:     $SUPA_SITE.supa.page   (if visibility=public)"
    ;;
  401)
    supa::audit_log publish site="$SUPA_SITE" status=401 outcome=expired
    echo "Session expired — run /signin." >&2
    exit 2
    ;;
  *)
    supa::audit_log publish site="$SUPA_SITE" status="$http_status" outcome=failed
    echo "API error ($http_status): $payload" >&2
    exit 1
    ;;
esac
