#!/usr/bin/env bash
# /signin (step 3, first-time only) — POST /api/welcome with the workspace name.
set -euo pipefail

WORKSPACE_NAME="${1:-}"
SERVER="${SUPA_PAGE_SERVER:-${2:-https://supa.page}}"
TOKEN="${SUPA_TOKEN:-}"

if [ -z "$WORKSPACE_NAME" ] || [ -z "$TOKEN" ]; then
  echo "signin-welcome.sh: usage: SUPA_TOKEN=<bearer> signin-welcome.sh <workspace-name> [server]" >&2
  exit 64
fi

RESP="$(curl -sS -X POST "$SERVER/api/welcome" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "$(jq -cn --arg n "$WORKSPACE_NAME" '{name: $n}')")"

if ! echo "$RESP" | jq -e '.org.slug' >/dev/null 2>&1; then
  echo "supa.page: workspace creation failed: $RESP" >&2
  exit 1
fi

name="$(echo "$RESP" | jq -r '.org.name')"
slug="$(echo "$RESP" | jq -r '.org.slug')"

email="$(curl -sS "$SERVER/api/me" -H "Authorization: Bearer $TOKEN" | jq -r '.user.email')"

echo "✓ Signed in as $email"
echo "  Workspace: $name ($SERVER/orgs/$slug)"
echo "  Run /new <site-name> to create your first site."
