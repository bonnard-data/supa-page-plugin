#!/usr/bin/env bash
# /domain-recheck <domain> — force an immediate DNS re-check.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1090
source "$HERE/../lib/api.sh"

DOMAIN="${1:-}"

supa::ensure_deps      || exit 1
supa::ensure_signed_in || {
  echo "Run /signin first." >&2
  exit 2
}

if [ -z "$DOMAIN" ]; then
  echo "Usage: /domain-recheck <domain>   (run /domain-list first to see options)" >&2
  exit 64
fi

RESP="$(supa::api POST "/api/domains/$DOMAIN/recheck")"
http_status="$(echo "$RESP" | head -1)"
payload="$(echo "$RESP" | tail -n +2)"

case "$http_status" in
  2*) ;;
  401) echo "Session expired — run /signin." >&2; exit 2 ;;
  404) echo "Domain not registered, or not owned by you." >&2; exit 1 ;;
  *)   echo "API error ($http_status): $payload" >&2; exit 1 ;;
esac

status="$(echo "$payload" | jq -r '.status')"
observed="$(echo "$payload" | jq -r '.observed | join(", ")')"
expected="$(echo "$payload" | jq -r '.expected | join(", ")')"

case "$status" in
  dns_verified|active)
    echo "✓ $DOMAIN is configured correctly. HTTPS will be issued on the first request (if not already active)."
    ;;
  pending_dns)
    echo "⏳ $DOMAIN isn't resolving yet. DNS may still be propagating."
    ;;
  error_dns)
    echo "⚠ $DOMAIN resolves to $observed, but we expected $expected. Check DNS records at your registrar."
    ;;
  *)
    echo "Status: $status"
    ;;
esac
