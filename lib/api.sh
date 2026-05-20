#!/usr/bin/env bash
# supa.page shared library — sourced by command markdown bash blocks.
#
# v0.1.3 hard-cut the auth model: the plugin now reads a single BA session
# bearer from ~/.config/supa-page/session.json and sends the site name in
# every request body. No per-site sync_token, no .supa-page.json secrets.
#
# Functions exposed:
#   supa::ensure_deps                — verify curl + jq are present
#   supa::find_site_config           — walk up from $PWD; sets $SUPA_CONFIG, $SUPA_SITE, $SUPA_SERVER
#   supa::ensure_signed_in           — fail if ~/.config/supa-page/session.json missing; sets $SUPA_TOKEN
#   supa::api <method> <path> [body] — curl wrapper; echoes "<status> <body>" on stdout
#
# Designed to be sourced (not executed). All state lives in global vars
# prefixed `SUPA_`; callers can rely on them after a successful invocation.

set -euo pipefail

# ── dependencies ────────────────────────────────────────────────────────
supa::ensure_deps() {
  local missing=()
  command -v curl >/dev/null 2>&1 || missing+=("curl")
  command -v jq   >/dev/null 2>&1 || missing+=("jq")
  if [ ${#missing[@]} -gt 0 ]; then
    echo "supa.page: missing required tools: ${missing[*]}" >&2
    echo "  Install with: brew install ${missing[*]}  (macOS)  or  apt install ${missing[*]}  (Linux)" >&2
    return 1
  fi
}

# ── locate the site config ──────────────────────────────────────────────
#
# Walks up from $PWD looking for .supa-page.json. v0.1.3+ that file carries
# only {site, server} — no token. v0.1.2 and earlier carried a `token` field;
# we ignore it and emit a one-time migration hint.
supa::find_site_config() {
  local dir
  dir="$(pwd)"
  SUPA_CONFIG=""
  while [ "$dir" != "/" ] && [ -n "$dir" ]; do
    if [ -f "$dir/.supa-page.json" ]; then
      SUPA_CONFIG="$dir/.supa-page.json"
      SUPA_DIR="$dir"
      break
    fi
    dir="$(dirname "$dir")"
  done
  if [ -z "$SUPA_CONFIG" ]; then
    echo "supa.page: not in a site directory. Run /new to create one, or cd into an existing site." >&2
    return 1
  fi
  SUPA_SITE="$(jq -r '.site' "$SUPA_CONFIG" 2>/dev/null || echo '')"
  SUPA_SERVER="$(jq -r '.server' "$SUPA_CONFIG" 2>/dev/null || echo '')"
  if [ -z "$SUPA_SITE" ] || [ "$SUPA_SITE" = "null" ]; then
    echo "supa.page: $SUPA_CONFIG is missing 'site'. Re-run /new or fix the file." >&2
    return 1
  fi
  if [ -z "$SUPA_SERVER" ] || [ "$SUPA_SERVER" = "null" ]; then
    SUPA_SERVER="${SUPA_PAGE_SERVER:-https://supa.page}"
  fi
  # Pre-v0.1.3 configs carried a `token` field. Warn once; nothing reads it now.
  if jq -e 'has("token")' "$SUPA_CONFIG" >/dev/null 2>&1; then
    echo "supa.page: $SUPA_CONFIG still has a legacy 'token' field — safe to remove. Use /signin once and it stays unused." >&2
  fi
  export SUPA_CONFIG SUPA_DIR SUPA_SITE SUPA_SERVER
}

# ── session bearer ──────────────────────────────────────────────────────
supa::ensure_signed_in() {
  local sf="${XDG_CONFIG_HOME:-$HOME/.config}/supa-page/session.json"
  if [ ! -f "$sf" ]; then
    echo "supa.page: not signed in. Run /signin to authorize this machine." >&2
    return 2
  fi
  SUPA_TOKEN="$(jq -r '.session_token' "$sf" 2>/dev/null || echo '')"
  if [ -z "$SUPA_TOKEN" ] || [ "$SUPA_TOKEN" = "null" ]; then
    echo "supa.page: session file malformed at $sf. Re-run /signin." >&2
    return 2
  fi
  # Allow the session file to override the server (useful for staging).
  local sess_server
  sess_server="$(jq -r '.server // empty' "$sf" 2>/dev/null || echo '')"
  if [ -n "$sess_server" ] && [ -z "${SUPA_SERVER:-}" ]; then
    SUPA_SERVER="$sess_server"
  fi
  export SUPA_TOKEN SUPA_SERVER
}

# ── audit log ───────────────────────────────────────────────────────────
#
# One structured JSON line per user-visible action — signin, signout, publish,
# rollback, visibility change, domain add/remove. Lives at ~/.claude/audit.log
# so it's discoverable alongside other Claude Code state.
#
# Truncates from the head when the file exceeds 10K lines (keep ~last 10K).
# Best-effort: any failure is silent — never block the user.
#
# Usage:
#   supa::audit_log <event> [key=value ...]
#
# Example:
#   supa::audit_log publish site="$SUPA_SITE" snapshot="$SNAP" message="$MSG" status=200
AUDIT_LOG="${SUPA_AUDIT_LOG:-${XDG_DATA_HOME:-$HOME/.claude}/audit.log}"
AUDIT_MAX_LINES=10000

supa::audit_log() {
  local event="$1"; shift || true
  local ts user
  ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  user="${SUPA_PAGE_USER_EMAIL:-${USER:-?}}"
  # Build a JSON object from the remaining key=value pairs. We jq-escape
  # values via --arg so embedded quotes / newlines / pipes can't corrupt
  # the audit line.
  local jq_args=(-cn --arg evt "$event" --arg ts "$ts" --arg user "$user")
  local obj='{evt: $evt, ts: $ts, user: $user, plugin: "supa-page"'
  for kv in "$@"; do
    local k="${kv%%=*}"
    local v="${kv#*=}"
    # Skip malformed entries.
    [ "$k" = "$kv" ] && continue
    jq_args+=(--arg "$k" "$v")
    obj+=", $k: \$$k"
  done
  obj+='}'
  local line
  line="$(jq "${jq_args[@]}" "$obj" 2>/dev/null || echo '')"
  [ -z "$line" ] && return 0
  mkdir -p "$(dirname "$AUDIT_LOG")" 2>/dev/null
  echo "$line" >> "$AUDIT_LOG" 2>/dev/null || return 0
  # Rotate: keep ~last N lines when we exceed the cap.
  local lines
  lines="$(wc -l < "$AUDIT_LOG" 2>/dev/null || echo 0)"
  if [ "$lines" -gt $((AUDIT_MAX_LINES + 1000)) ] 2>/dev/null; then
    tail -n "$AUDIT_MAX_LINES" "$AUDIT_LOG" > "$AUDIT_LOG.tmp" \
      && mv "$AUDIT_LOG.tmp" "$AUDIT_LOG"
  fi
  return 0
}

# ── workflow lock ───────────────────────────────────────────────────────
#
# Per-project lockfile at .claude/supa-page-plugin.local.lock — held for the
# duration of a /publish (or /rollback) call. The authoritative concurrency
# guard is the server-side per-site mutex in src/snapshots.ts; this lock is
# just a guardrail so a user doesn't accidentally race themselves by hitting
# /publish twice in two terminals before the first round-trip completes.
#
# Usage:
#   supa::acquire_lock /publish || exit 1
#   trap 'supa::release_lock' EXIT
#   ... do the work ...
#
# The lock file carries the calling command + timestamp + PID so a stale
# lock (older than 60s, or whose PID is dead) is auto-evicted.
LOCK_DIR=".claude"
LOCK_FILE=".claude/supa-page-plugin.local.lock"
LOCK_MAX_AGE_S=60

supa::acquire_lock() {
  local what="${1:-unknown}"
  : "${SUPA_DIR:?call supa::find_site_config first}"
  local lockdir="$SUPA_DIR/$LOCK_DIR"
  local lockfile="$SUPA_DIR/$LOCK_FILE"
  mkdir -p "$lockdir"
  if [ -f "$lockfile" ]; then
    local now age existing_pid existing_cmd existing_ts
    now="$(date +%s)"
    existing_ts="$(jq -r '.ts // 0' "$lockfile" 2>/dev/null || echo 0)"
    existing_pid="$(jq -r '.pid // 0' "$lockfile" 2>/dev/null || echo 0)"
    existing_cmd="$(jq -r '.cmd // "?"' "$lockfile" 2>/dev/null || echo '?')"
    age=$((now - existing_ts))
    # Stale: older than max age, or holding PID is dead.
    if [ "$age" -gt "$LOCK_MAX_AGE_S" ] || ! kill -0 "$existing_pid" 2>/dev/null; then
      echo "supa.page: clearing stale lock (held by $existing_cmd, pid=$existing_pid, age=${age}s)." >&2
      rm -f "$lockfile"
    else
      echo "supa.page: another $existing_cmd is already running here (pid=$existing_pid, ${age}s ago). Wait or kill that process." >&2
      return 2
    fi
  fi
  jq -cn --arg c "$what" --arg p "$$" --arg t "$(date +%s)" \
    '{cmd: $c, pid: ($p|tonumber), ts: ($t|tonumber)}' > "$lockfile"
}

supa::release_lock() {
  : "${SUPA_DIR:=}"
  [ -n "$SUPA_DIR" ] && rm -f "$SUPA_DIR/$LOCK_FILE"
}

# ── HTTP helper ─────────────────────────────────────────────────────────
#
# Usage: supa::api METHOD PATH [BODY_JSON]
#   - prints `<HTTP_STATUS>\n<RESPONSE_BODY>` on stdout
#   - exit code: 0 on 2xx, 2 on 401, 1 on any other non-2xx
supa::api() {
  local method="$1"
  local path="$2"
  local body="${3:-}"
  local args=(
    -sS
    -X "$method"
    -H "Authorization: Bearer $SUPA_TOKEN"
  )
  if [ -n "$body" ]; then
    args+=(-H 'Content-Type: application/json' -d "$body")
  fi
  local tmp
  # Portable mktemp invocation: `-t` differs between GNU and BSD. Use the
  # template-as-path form which both honour identically.
  tmp="$(mktemp "${TMPDIR:-/tmp}/supa-api.XXXXXX")"
  local status
  status="$(curl "${args[@]}" -o "$tmp" -w '%{http_code}' "$SUPA_SERVER$path" 2>/dev/null || echo '000')"
  local resp
  resp="$(cat "$tmp" 2>/dev/null || echo '')"
  rm -f "$tmp"
  printf '%s\n%s\n' "$status" "$resp"
  case "$status" in
    2*) return 0 ;;
    401) return 2 ;;
    *) return 1 ;;
  esac
}
