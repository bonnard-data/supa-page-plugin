#!/usr/bin/env bash
# /visibility <public|private> — set site visibility.
#
# Exit codes:
#   0  — success
#   2  — auth needed
#   64 — empty/invalid value; skill should ask the user
#   1  — other error
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1090
source "$HERE/../lib/api.sh"

VALUE="${1:-}"

supa::ensure_deps      || exit 1
supa::find_site_config || exit 1
supa::ensure_signed_in || {
  echo "Run /signin first, then /visibility again." >&2
  exit 2
}

case "$VALUE" in
  public|private) ;;
  "")
    echo "visibility.sh: needs 'public' or 'private' — skill should ask the user." >&2
    exit 64
    ;;
  *)
    echo "visibility.sh: invalid value '$VALUE' — must be 'public' or 'private'." >&2
    exit 64
    ;;
esac

BODY="$(jq -cn --arg v "$VALUE" '{visibility: $v}')"
RESP="$(supa::api PUT "/api/sites/$SUPA_SITE/visibility" "$BODY")"
http_status="$(echo "$RESP" | head -1)"
payload="$(echo "$RESP" | tail -n +2)"

case "$http_status" in
  2*)
    supa::audit_log visibility site="$SUPA_SITE" value="$VALUE" status=200
    echo "✓ $SUPA_SITE.supa.page is now $VALUE."
    if [ "$VALUE" = "public" ]; then
      echo "  Anyone with the URL can view it."
    else
      echo "  Visitors are redirected to sign in; only org members get through."
    fi
    ;;
  401) echo "Session expired — run /signin." >&2; exit 2 ;;
  400) echo "$payload" | jq -r '.message // "Invalid visibility value."' >&2; exit 1 ;;
  *)   echo "API error ($http_status): $payload" >&2; exit 1 ;;
esac
