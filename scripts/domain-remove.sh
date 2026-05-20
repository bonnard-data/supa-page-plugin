#!/usr/bin/env bash
# /domain-remove <domain> — unregister a custom domain from the current site.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1090
source "$HERE/../lib/api.sh"

DOMAIN="${1:-}"

supa::ensure_deps      || exit 1
supa::find_site_config || exit 1
supa::ensure_signed_in || {
  echo "Run /signin first." >&2
  exit 2
}

if [ -z "$DOMAIN" ]; then
  echo "Usage: /domain-remove <domain>   (e.g. www.example.com)" >&2
  exit 64
fi
if [[ ! "$DOMAIN" =~ ^([a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z]{2,}$ ]]; then
  echo "supa.page: '$DOMAIN' is not a valid domain shape." >&2
  exit 64
fi

RESP="$(supa::api DELETE "/api/domains/$DOMAIN")"
http_status="$(echo "$RESP" | head -1)"

supa::audit_log domain-remove site="$SUPA_SITE" domain="$DOMAIN" status="$http_status"

case "$http_status" in
  2*)  echo "✓ Removed $DOMAIN" ;;
  401) echo "Session expired — run /signin." >&2; exit 2 ;;
  404) echo "Domain not registered, or not owned by you. Run /domain-list to confirm." >&2; exit 1 ;;
  *)   echo "API error ($http_status)." >&2; exit 1 ;;
esac
