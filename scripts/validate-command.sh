#!/usr/bin/env bash
# validate-skill.sh — pre-flight check for user-invoked SKILL.md files.
#
# Usage:
#   bash validate-command.sh plugin/skills/*/SKILL.md
#   bash validate-command.sh  (defaults to plugin/skills/*/SKILL.md from $PWD)
#
# v0.1.4: this script used to scan plugin/commands/*.md back when slash commands
# lived in the legacy commands/ layout. Now everything is skills — but knowledge
# skills use a different frontmatter shape (name + description + version) than
# action skills (description + allowed-tools + model). This validator targets
# only the action-skill frontmatter shape.
#
# Catches:
#   - missing frontmatter
#   - missing required 'description'
#   - invalid model value
#   - invalid allowed-tools shape
#   - description over /help-friendly length (warning)
#
# Run from the supa-page repo root, or pass paths explicitly.
#
# Designed for both:
#   - manual invocation while editing a skill
#   - pre-commit hook ($ for f in $(git diff --cached --name-only | grep 'plugin/skills/.*/SKILL\.md$'); do bash plugin/scripts/validate-command.sh "$f"; done)
set -uo pipefail

VALID_MODELS="haiku sonnet opus inherit"
DESC_WARN=80    # chars — clean /help display

# Color codes (only used if stdout is a tty).
if [ -t 1 ]; then
  RED=$'\e[31m'; YELLOW=$'\e[33m'; GREEN=$'\e[32m'; RESET=$'\e[0m'
else
  RED=''; YELLOW=''; GREEN=''; RESET=''
fi

FAIL_COUNT=0
WARN_COUNT=0
PASS_COUNT=0

validate_one() {
  local f="$1"
  local errs=()
  local warns=()

  if [ ! -f "$f" ]; then
    errs+=("file does not exist")
    printf '%s ERROR%s %s\n' "$RED" "$RESET" "$f"
    for e in "${errs[@]}"; do printf '  • %s\n' "$e"; done
    FAIL_COUNT=$((FAIL_COUNT + 1))
    return
  fi

  # Extract the YAML frontmatter block.
  local fm
  fm="$(awk '/^---$/{c++; next} c==1 && c<2 {print}' "$f")"
  if [ -z "$fm" ]; then
    errs+=("missing or empty YAML frontmatter (no '---' delimiters at top)")
  fi

  # description required. (name: was required in legacy commands/ frontmatter
  # but action-skill SKILL.md takes its name from the parent directory.)
  if ! echo "$fm" | grep -qE '^description:\s+\S'; then
    errs+=("missing 'description:' in frontmatter")
  fi

  # description length (warn)
  local desc
  desc="$(echo "$fm" | sed -nE 's/^description:\s*(.*)$/\1/p' | head -1)"
  if [ -n "$desc" ] && [ "${#desc}" -gt "$DESC_WARN" ]; then
    warns+=("description is ${#desc} chars (clean /help renders best at <=$DESC_WARN)")
  fi

  # model field — if present, must be in VALID_MODELS
  local model
  model="$(echo "$fm" | sed -nE 's/^model:\s*(\S+).*$/\1/p' | head -1)"
  if [ -n "$model" ] && ! echo " $VALID_MODELS " | grep -q " $model "; then
    errs+=("invalid model value '$model' — must be one of: $VALID_MODELS")
  fi

  # disable-model-invocation — if present, must be boolean
  if echo "$fm" | grep -qE '^disable-model-invocation:'; then
    if ! echo "$fm" | grep -qE '^disable-model-invocation:\s*(true|false)\s*$'; then
      errs+=("disable-model-invocation must be 'true' or 'false'")
    fi
  fi

  # allowed-tools — if present, comma-separated word list (we don't validate the tool names themselves)
  if echo "$fm" | grep -qE '^allowed-tools:'; then
    local at
    at="$(echo "$fm" | sed -nE 's/^allowed-tools:\s*(.*)$/\1/p' | head -1)"
    if [ -z "$at" ]; then
      errs+=("allowed-tools is empty — remove the field or list tools")
    fi
  fi

  # Print result for this file
  if [ ${#errs[@]} -eq 0 ] && [ ${#warns[@]} -eq 0 ]; then
    printf '%s PASS%s  %s\n' "$GREEN" "$RESET" "$f"
    PASS_COUNT=$((PASS_COUNT + 1))
  elif [ ${#errs[@]} -eq 0 ]; then
    printf '%s WARN%s  %s\n' "$YELLOW" "$RESET" "$f"
    for w in "${warns[@]}"; do printf '  • %s\n' "$w"; done
    WARN_COUNT=$((WARN_COUNT + 1))
  else
    printf '%s ERROR%s %s\n' "$RED" "$RESET" "$f"
    for e in "${errs[@]}"; do printf '  • %s\n' "$e"; done
    for w in "${warns[@]}"; do printf '  • (warn) %s\n' "$w"; done
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
}

main() {
  if [ "$#" -gt 0 ]; then
    for f in "$@"; do validate_one "$f"; done
  else
    # Default: walk plugin/skills/*/SKILL.md from current dir
    if [ ! -d plugin/skills ]; then
      echo "Usage: $0 [files...]   (or run from supa-page repo root)" >&2
      exit 2
    fi
    # Only validate action-skill SKILL.md (those with description + allowed-tools);
    # knowledge skills use a different frontmatter shape and aren't covered here.
    for f in plugin/skills/*/SKILL.md; do
      if grep -qE '^allowed-tools:' "$f"; then
        validate_one "$f"
      fi
    done
  fi

  echo
  echo "Summary: $PASS_COUNT pass, $WARN_COUNT warn, $FAIL_COUNT error"
  [ "$FAIL_COUNT" -eq 0 ]
}

main "$@"
