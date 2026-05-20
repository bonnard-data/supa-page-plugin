#!/usr/bin/env bash
# supa.page PreToolUse secret-scan hook
#
# Fires before any Write/Edit/MultiEdit inside a tracked supa.page site dir.
# Scans the proposed content for high-confidence credential patterns and
# blocks the write with exit 2 + a structured JSON message so Claude sees
# the rejection and can re-author without the secret.
#
# Tradeoffs:
#   - We deliberately keep the regex set tight to avoid false positives on
#     marketing copy ("the password is hidden" shouldn't trigger).
#   - We only run on edits inside a directory containing .supa-page.json —
#     no impact on the user's other repos.
#   - On any error in the hook itself we exit 0 (allow). Better to ship a
#     leaky write than break the session over a hook bug.
set -euo pipefail

INPUT="$(cat)"
FILE_PATH="$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null || echo '')"
[ -z "$FILE_PATH" ] && exit 0

# Walk up looking for .supa-page.json — only scan inside tracked sites.
DIR="$(cd "$(dirname "$FILE_PATH")" 2>/dev/null && pwd || true)"
while [ -n "$DIR" ] && [ "$DIR" != "/" ]; do
  [ -f "$DIR/.supa-page.json" ] && break
  DIR="$(dirname "$DIR")"
done
[ -z "$DIR" ] || [ ! -f "$DIR/.supa-page.json" ] && exit 0

# Extract the content the tool wants to write. For Edit/MultiEdit we get
# `new_string` (Edit) or an array of edits with `new_string` (MultiEdit).
# For Write we get `content`. Concatenate so the scan covers all of them.
CONTENT="$(
  printf '%s' "$INPUT" | jq -r '
    [
      .tool_input.content // "",
      .tool_input.new_string // "",
      ((.tool_input.edits // []) | map(.new_string // "") | join("\n"))
    ] | join("\n")
  ' 2>/dev/null || echo ''
)"
[ -z "$CONTENT" ] && exit 0

# Pattern set: high-confidence credential shapes only. Each entry is
# "label|pattern" — we report the first hit with the label so Claude can
# act on it without us leaking the matched text.
HITS=""
declare -a PATTERNS=(
  "Stripe live secret key|sk_live_[A-Za-z0-9]{20,}"
  "Stripe restricted key|rk_live_[A-Za-z0-9]{20,}"
  "AWS access key id|AKIA[0-9A-Z]{16}"
  "GitHub fine-grained PAT|github_pat_[A-Za-z0-9_]{40,}"
  "GitHub classic PAT|ghp_[A-Za-z0-9]{30,}"
  "Slack bot token|xox[baprs]-[A-Za-z0-9-]{20,}"
  "OpenAI key|sk-[A-Za-z0-9]{30,}"
  "Anthropic key|sk-ant-[A-Za-z0-9_-]{30,}"
  "Resend key|re_[A-Za-z0-9]{20,}"
  "Generic Bearer token|Bearer\s+[A-Za-z0-9._-]{40,}"
  "Private SSH key block|-----BEGIN[ A-Z]+PRIVATE KEY-----"
  "supa.page session token|supa_sess_[A-Za-z0-9_-]{20,}"
)

for entry in "${PATTERNS[@]}"; do
  label="${entry%%|*}"
  pat="${entry#*|}"
  # Use -e so patterns starting with `-` (e.g. PEM banners) aren't parsed as flags.
  if printf '%s' "$CONTENT" | grep -qE -e "$pat"; then
    HITS="${HITS:+$HITS, }$label"
  fi
done

if [ -n "$HITS" ]; then
  REL="${FILE_PATH#$DIR/}"
  # Exit 2 → blocking. stderr is fed back to Claude so it can re-author.
  cat >&2 <<EOF
supa.page secret-scan: refusing to write $REL — looks like it contains: $HITS.

Marketing copy and JSON site content shouldn't carry live credentials.
If this is a placeholder you intended to publish (e.g. demoing what a
secret looks like), rewrite the value as XXX-style placeholder text.

If you believe this is a false positive, edit the file with a slightly
different shape (e.g. break the token across two lines).
EOF
  exit 2
fi

exit 0
