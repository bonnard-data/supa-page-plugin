#!/usr/bin/env bash
# /new <site-name> — reserve a site on the server + scaffold local files in ./<name>/.
#
# Exit codes:
#   0  — success
#   2  — auth needed
#   64 — empty/invalid name; skill should ask the user
#   1  — generic error (taken, server error)
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1090
source "$HERE/../lib/api.sh"

NAME="${1:-}"

supa::ensure_deps || exit 1
supa::ensure_signed_in || {
  echo "Run /signin first, then re-run /new <name>." >&2
  exit 2
}

if [ -z "$NAME" ]; then
  echo "new.sh: missing <name> arg." >&2
  exit 64
fi
if [[ ! "$NAME" =~ ^[a-z0-9]([a-z0-9-]{0,62}[a-z0-9])?$ ]]; then
  echo "supa.page: '$NAME' is not a valid site name. Use lowercase kebab-case, 1-64 chars, start/end alphanumeric." >&2
  exit 64
fi

SITE_DIR="${PWD}/$NAME"
if [ -f "$SITE_DIR/.supa-page.json" ]; then
  echo "supa.page: $SITE_DIR is already a supa.page site." >&2
  echo "  cd into it and run /status to see the current state, or pick a different name." >&2
  exit 1
fi

# Reserve on the server.
BODY="$(jq -cn --arg n "$NAME" '{name: $n}')"
RESP="$(supa::api POST /api/sites "$BODY")"
http_status="$(echo "$RESP" | head -1)"
payload="$(echo "$RESP" | tail -n +2)"

case "$http_status" in
  2*) ;;
  401) echo "Session expired — run /signin." >&2; exit 2 ;;
  409) echo "$payload" | jq -r '.message // "Name already taken — pick another."' >&2; exit 1 ;;
  *)   echo "API error ($http_status): $payload" >&2; exit 1 ;;
esac

# Scaffold local files.
mkdir -p "$SITE_DIR/source/pages"

jq -cn --arg s "$NAME" --arg srv "$SUPA_SERVER" '{site: $s, server: $srv}' \
  > "$SITE_DIR/.supa-page.json"

cat > "$SITE_DIR/source/site.json" <<EOF
{
  "title": "$NAME",
  "description": "",
  "theme": "default"
}
EOF

cat > "$SITE_DIR/source/pages/index.json" <<EOF
{
  "title": "$NAME",
  "description": "",
  "sections": [
    {
      "type": "hero",
      "title": "$NAME.",
      "description": "Something is being built here."
    }
  ]
}
EOF

supa::audit_log new site="$NAME" status=200 || true

cat <<EOF
✓ Site "$NAME" created (beta — v0.1.4).
  Preview (latest published): $SUPA_SERVER/?preview=$NAME
  Live (once visibility = public): $NAME.supa.page

New sites are visibility=private by default. Toggle with /visibility public.
EOF
