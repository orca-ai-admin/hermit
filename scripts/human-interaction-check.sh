#!/usr/bin/env bash
# human-interaction-check.sh — Detect when the human goes quiet.
#
# Usage: human-interaction-check.sh [--json] [--sessions-dir /path]
#
# Scans session logs for most recent real human message, filtering out
# system-injected messages (cron, bootstrap, heartbeat, forwarded).
#
# Exit codes: 0=OK (≤2 days), 1=WARNING (3-5 days), 2=CRITICAL (>5 days), 3=UNKNOWN

set -euo pipefail

# --- Configuration -----------------------------------------------------------
WORKSPACE="${HERMIT_WORKSPACE:-${PWD}}"
SESSIONS_DIR="${HERMIT_SESSIONS_DIR:-${HOME}/.openclaw/sessions}"
JSON_OUTPUT=false

# Thresholds in days
OK_THRESHOLD=2
WARN_THRESHOLD=5

# System message patterns to filter out
SYSTEM_PATTERNS='(cron|heartbeat|bootstrap|forwarded|system|automated|scheduled|HEARTBEAT|Subagent|subagent|injected)'

# --- Argument parsing --------------------------------------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --json|-j)         JSON_OUTPUT=true; shift ;;
    --sessions-dir|-s) SESSIONS_DIR="$2"; shift 2 ;;
    --help|-h)
      echo "Usage: $(basename "$0") [--json] [--sessions-dir /path]"
      echo ""
      echo "Detects when the human goes quiet by scanning session logs."
      echo ""
      echo "Exit codes:"
      echo "  0  OK       — last interaction ≤${OK_THRESHOLD} days ago"
      echo "  1  WARNING  — last interaction 3-${WARN_THRESHOLD} days ago"
      echo "  2  CRITICAL — last interaction >${WARN_THRESHOLD} days ago"
      echo "  3  UNKNOWN  — could not determine"
      echo ""
      echo "Env vars:"
      echo "  HERMIT_SESSIONS_DIR  Path to session log directory"
      exit 0
      ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

# --- Main --------------------------------------------------------------------

if [[ ! -d "$SESSIONS_DIR" ]]; then
  if $JSON_OUTPUT; then
    echo '{"status":"unknown","reason":"sessions_dir_not_found","sessions_dir":"'"$SESSIONS_DIR"'"}'
  else
    echo "UNKNOWN: Sessions directory not found: ${SESSIONS_DIR}"
  fi
  exit 3
fi

# Find the most recent human message across session files
# Look for JSON session files or plain text logs
latest_human_epoch=0
latest_human_date="unknown"
sessions_checked=0

# Check recent session files (last 30 days worth, newest first)
while IFS= read -r session_file; do
  (( sessions_checked++ )) || true

  if command -v jq &>/dev/null && jq empty "$session_file" 2>/dev/null; then
    # JSON session file — look for user/human role messages
    # Filter out system-injected messages
    while IFS= read -r ts; do
      [[ -z "$ts" || "$ts" == "null" ]] && continue
      # Parse timestamp to epoch
      local_epoch=0
      if local_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%S" "${ts%%[.Z+]*}" +%s 2>/dev/null) || \
         local_epoch=$(date -d "$ts" +%s 2>/dev/null); then
        if (( local_epoch > latest_human_epoch )); then
          latest_human_epoch=$local_epoch
          latest_human_date="$ts"
        fi
      fi
    done < <(jq -r '
      .messages[]? |
      select(.role == "user" or .role == "human") |
      select(.content? | tostring | test("'"$SYSTEM_PATTERNS"'") | not) |
      .timestamp // .created_at // .date // empty
    ' "$session_file" 2>/dev/null)
  else
    # Plain text or other format — check file modification time for user-like content
    if grep -qiE '^(user|human):' "$session_file" 2>/dev/null; then
      # Get lines that look like human messages, excluding system patterns
      local last_human_line
      last_human_line=$(grep -iE '^(user|human):' "$session_file" 2>/dev/null | \
                        grep -viE "$SYSTEM_PATTERNS" 2>/dev/null | \
                        tail -1)
      if [[ -n "$last_human_line" ]]; then
        # Use file modification time as approximation
        local file_epoch=0
        if file_epoch=$(stat -f %m "$session_file" 2>/dev/null) || \
           file_epoch=$(stat -c %Y "$session_file" 2>/dev/null); then
          if (( file_epoch > latest_human_epoch )); then
            latest_human_epoch=$file_epoch
            latest_human_date=$(date -r "$file_epoch" +%Y-%m-%dT%H:%M:%S 2>/dev/null || echo "unknown")
          fi
        fi
      fi
    fi
  fi

  # Stop after checking enough files
  (( sessions_checked >= 100 )) && break

done < <(find "$SESSIONS_DIR" -type f \( -name '*.json' -o -name '*.jsonl' -o -name '*.log' \) \
         -mtime -30 2>/dev/null | sort -r)

# If no JSON sessions found, try checking daily memory files as fallback
if (( latest_human_epoch == 0 )) && [[ -d "${WORKSPACE}/memory" ]]; then
  # Most recent memory file with human interaction indicators
  while IFS= read -r mem_file; do
    local basename_file
    basename_file=$(basename "$mem_file" .md)
    # Try to parse YYYY-MM-DD from filename
    if [[ "$basename_file" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
      if grep -qiE '(asked|told|said|requested|wanted|Aston|human|user)' "$mem_file" 2>/dev/null && \
         ! grep -qiE '(no.?interaction|silent|quiet|away)' "$mem_file" 2>/dev/null; then
        local mem_epoch=0
        if mem_epoch=$(date -j -f "%Y-%m-%d" "$basename_file" +%s 2>/dev/null) || \
           mem_epoch=$(date -d "$basename_file" +%s 2>/dev/null); then
          if (( mem_epoch > latest_human_epoch )); then
            latest_human_epoch=$mem_epoch
            latest_human_date="${basename_file}"
          fi
        fi
      fi
    fi
  done < <(find "${WORKSPACE}/memory" -maxdepth 1 -name '????-??-??.md' -type f 2>/dev/null | sort -r | head -30)
fi

# Calculate age
now_epoch=$(date +%s)
if (( latest_human_epoch > 0 )); then
  age_seconds=$(( now_epoch - latest_human_epoch ))
  age_days=$(( age_seconds / 86400 ))
  age_hours=$(( age_seconds / 3600 ))

  if (( age_days <= OK_THRESHOLD )); then
    status="OK"
    exit_code=0
  elif (( age_days <= WARN_THRESHOLD )); then
    status="WARNING"
    exit_code=1
  else
    status="CRITICAL"
    exit_code=2
  fi

  if $JSON_OUTPUT; then
    cat <<EOF
{
  "status": "$(echo "$status" | tr '[:upper:]' '[:lower:]')",
  "last_interaction": "${latest_human_date}",
  "age_hours": ${age_hours},
  "age_days": ${age_days},
  "sessions_checked": ${sessions_checked},
  "threshold_warn_days": ${WARN_THRESHOLD},
  "threshold_ok_days": ${OK_THRESHOLD}
}
EOF
  else
    echo "${status}: Last human interaction ${age_days} day(s) ago (${age_hours}h)"
    echo "  Last seen: ${latest_human_date}"
    echo "  Sessions checked: ${sessions_checked}"
  fi

  exit "$exit_code"
else
  if $JSON_OUTPUT; then
    cat <<EOF
{
  "status": "unknown",
  "reason": "no_human_messages_found",
  "sessions_checked": ${sessions_checked}
}
EOF
  else
    echo "UNKNOWN: Could not find any human messages in recent sessions."
    echo "  Sessions checked: ${sessions_checked}"
    echo "  Sessions dir: ${SESSIONS_DIR}"
  fi
  exit 3
fi
