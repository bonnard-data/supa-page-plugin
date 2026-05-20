#!/usr/bin/env bash
# /rollback (step 2) — flip current.json to the chosen snapshot.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1090
source "$HERE/../lib/api.sh"

SNAPSHOT="${1:-}"

supa::ensure_deps      || exit 1
supa::find_site_config || exit 1
supa::ensure_signed_in || {
  echo "Run /signin first." >&2
  exit 2
}

if [ -z "$SNAPSHOT" ]; then
  echo "rollback-act.sh: missing <snapshot> arg." >&2
  exit 64
fi
if [[ ! "$SNAPSHOT" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}-[0-9]{2}-[0-9]{2}\.[0-9]{3}Z(-[0-9a-f]{8})?$ ]]; then
  echo "rollback-act.sh: '$SNAPSHOT' isn't a valid snapshot id." >&2
  exit 64
fi

if ! supa::acquire_lock /rollback; then
  exit 3
fi
trap 'supa::release_lock' EXIT

BODY="$(jq -cn --arg s "$SUPA_SITE" --arg snap "$SNAPSHOT" '{site: $s, snapshot: $snap}')"
RESP="$(supa::api POST /api/rollback "$BODY")"
http_status="$(echo "$RESP" | head -1)"
payload="$(echo "$RESP" | tail -n +2)"

case "$http_status" in
  2*)
    supa::audit_log rollback site="$SUPA_SITE" snapshot="$SNAPSHOT" status=200
    ts="$(echo "$payload" | jq -r '.timestamp // empty')"
    msg="$(echo "$payload" | jq -r '.message // empty')"
    echo "✓ Rolled back to $SNAPSHOT"
    [ -n "$ts" ]  && echo "  $ts — $msg"
    echo "  preview:  $SUPA_SERVER/?preview=$SUPA_SITE"
    ;;
  401) echo "Session expired — run /signin." >&2; exit 2 ;;
  404) echo "Snapshot not found, or its source/ is missing. Pick a different one (try /rollback)." >&2; exit 1 ;;
  *)   echo "API error ($http_status): $payload" >&2; exit 1 ;;
esac
