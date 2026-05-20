#!/usr/bin/env bash
# /domain-add <domain> — register a custom domain for the current site.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1090
source "$HERE/../lib/api.sh"

DOMAIN="${1:-}"

supa::ensure_deps      || exit 1
supa::find_site_config || exit 1
supa::ensure_signed_in || {
  echo "Run /signin first, then /domain-add <domain>." >&2
  exit 2
}

if [ -z "$DOMAIN" ]; then
  echo "Usage: /domain-add <domain>   (e.g. www.example.com)" >&2
  exit 64
fi

# Reject obviously wrong shapes locally before hitting the API.
if [[ "$DOMAIN" == "https://"* ]] || [[ "$DOMAIN" == "http://"* ]]; then
  echo "supa.page: drop the https:// prefix — just '$DOMAIN' as the domain." >&2
  exit 64
fi
if [[ ! "$DOMAIN" =~ ^([a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z]{2,}$ ]]; then
  echo "supa.page: '$DOMAIN' doesn't look like a valid domain. Examples: example.com, www.example.com" >&2
  exit 64
fi
if [[ "$DOMAIN" == *.supa.page ]]; then
  echo "supa.page: cannot register a *.supa.page host — those are reserved." >&2
  exit 64
fi

BODY="$(jq -cn --arg s "$SUPA_SITE" --arg d "$DOMAIN" '{site: $s, domain: $d}')"
RESP="$(supa::api POST /api/domains "$BODY")"
http_status="$(echo "$RESP" | head -1)"
payload="$(echo "$RESP" | tail -n +2)"

supa::audit_log domain-add site="$SUPA_SITE" domain="$DOMAIN" status="$http_status"

case "$http_status" in
  2*)
    cname_target="$(echo "$payload" | jq -r '.cname_target // empty')"
    a_record="$(echo "$payload" | jq -r '.apex_a_records[0] // empty')"
    is_apex="$(echo "$DOMAIN" | awk -F. '{print (NF == 2) ? "yes" : "no"}')"
    echo "✓ Added $DOMAIN"
    echo
    echo "Add this DNS record at your registrar:"
    if [ "$is_apex" = "yes" ]; then
      echo "  Type:   A"
      echo "  Name:   @"
      echo "  Value:  $a_record"
    else
      echo "  Type:   CNAME"
      echo "  Name:   $(echo "$DOMAIN" | sed 's/\..*//')"
      echo "  Value:  $cname_target"
    fi
    echo
    echo "HTTPS issues automatically once DNS propagates (usually < 5 min)."
    echo "Run /domain-list to check status."
    ;;
  401) echo "Session expired — run /signin." >&2; exit 2 ;;
  409) echo "$payload" | jq -r '.message // "Domain already claimed by another site."' >&2; exit 1 ;;
  400) echo "$payload" | jq -r '.message // "Invalid domain."' >&2; exit 1 ;;
  *)   echo "API error ($http_status): $payload" >&2; exit 1 ;;
esac
