#!/usr/bin/env bash
# /preview — open the staged-source preview URL in the default browser.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1090
source "$HERE/../lib/api.sh"

supa::find_site_config || exit 1

URL="${SUPA_SERVER}/?preview=${SUPA_SITE}"

case "$(uname)" in
  Darwin) open "$URL" 2>/dev/null || true ;;
  Linux)  xdg-open "$URL" 2>/dev/null || true ;;
  *)      start "$URL" 2>/dev/null || true ;;
esac

echo "Preview: $URL"
