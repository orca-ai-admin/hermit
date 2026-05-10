#!/usr/bin/env bash
# session-context-summarizer.sh — Preserve context before session rotation.
#
# Usage:
#   session-context-summarizer.sh              # Summarize all critical sessions
#   session-context-summarizer.sh --check      # Report only, don't write
#   session-context-summarizer.sh --session ID # Summarize specific session
#
# Extracts first and last N user/assistant messages from oversized sessions.

set -euo pipefail

# --- Configuration -----------------------------------------------------------
WORKSPACE="${HERMIT_WORKSPACE:-${PWD}}"
SESSION_DIR="${HERMIT_SESSION_DIR:-${HOME}/.openclaw/sessions}"
SUMMARY_DIR="${HERMIT_SUMMARY_DIR:-${WORKSPACE}/memory/session-summaries}"
CRITICAL_THRESHOLD="${HERMIT_SESSION_CRITICAL_KB:-500}"  # KB
EXTRACT_MESSAGES=10  # first N and last N messages to extract

# --- Argument parsing --------------------------------------------------------
MODE="summarize"
TARGET_SESSION=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --check|-c)    MODE="check"; shift ;;
    --session|-s)  MODE="single"; TARGET_SESSION="$2"; shift 2 ;;
    --threshold|-t) CRITICAL_THRESHOLD="$2"; shift 2 ;;
    --messages|-m)  EXTRACT_MESSAGES="$2"; shift 2 ;;
    --help|-h)
      echo "Usage: $(basename "$0") [--check] [--session ID] [--threshold KB] [--messages N]"
      echo ""
      echo "Preserves context from oversized sessions before rotation."
      echo ""
      echo "Modes:"
      echo "  (default)    Summarize all sessions over threshold"
      echo "  --check      Report oversized sessions without writing summaries"
      echo "  --session ID Summarize a specific session file"
      echo ""
      echo "Options:"
      echo "  --threshold  Size threshold in KB (default: ${CRITICAL_THRESHOLD})"
      echo "  --messages   Number of first/last messages to extract (default: ${EXTRACT_MESSAGES})"
      echo ""
      echo "Env vars:"
      echo "  HERMIT_SESSION_DIR          Session log directory"
      echo "  HERMIT_SUMMARY_DIR          Summary output directory"
      echo "  HERMIT_SESSION_CRITICAL_KB  Size threshold in KB"
      exit 0
      ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

# --- Helpers -----------------------------------------------------------------
threshold_bytes=$(( CRITICAL_THRESHOLD * 1024 ))

is_already_summarized() {
  local session_id="$1"
  [[ -f "${SUMMARY_DIR}/${session_id}-summary.md" ]]
}

extract_messages() {
  local file="$1"
  local role="$2"   # user or assistant
  local position="$3"  # first or last

  if ! command -v jq &>/dev/null; then
    echo "(jq not available — cannot extract messages)"
    return
  fi

  local jq_filter
  if [[ "$position" == "first" ]]; then
    jq_filter="[.messages[]? | select(.role == \"${role}\")] | .[0:${EXTRACT_MESSAGES}]"
  else
    jq_filter="[.messages[]? | select(.role == \"${role}\")] | .[-(${EXTRACT_MESSAGES}):]"
  fi

  jq -r "${jq_filter}[]? | \"### \" + (.role // \"unknown\") + \" (\" + (.timestamp // .created_at // \"?\") + \")\n\" + (.content // \"(empty)\") + \"\n\"" "$file" 2>/dev/null || true
}

summarize_session() {
  local session_file="$1"
  local session_id
  session_id=$(basename "$session_file" | sed 's/\.[^.]*$//')

  # Check if already summarized
  if is_already_summarized "$session_id"; then
    echo "  SKIP: ${session_id} (already summarized)"
    return
  fi

  local file_size
  file_size=$(wc -c < "$session_file" | tr -d ' ')
  local file_size_kb=$(( file_size / 1024 ))

  if [[ "$MODE" == "check" ]]; then
    echo "  OVERSIZED: ${session_id} (${file_size_kb}KB)"
    return
  fi

  mkdir -p "$SUMMARY_DIR"

  local summary_file="${SUMMARY_DIR}/${session_id}-summary.md"

  {
    echo "# Session Summary: ${session_id}"
    echo ""
    echo "- **Source**: \`${session_file}\`"
    echo "- **Size**: ${file_size_kb}KB"
    echo "- **Summarized**: $(date '+%Y-%m-%d %H:%M:%S %Z')"
    echo "- **Messages extracted**: first ${EXTRACT_MESSAGES} + last ${EXTRACT_MESSAGES} per role"
    echo ""

    # Try to get session metadata
    if command -v jq &>/dev/null && jq empty "$session_file" 2>/dev/null; then
      local total_messages
      total_messages=$(jq '[.messages[]?] | length' "$session_file" 2>/dev/null || echo "?")
      local user_messages
      user_messages=$(jq '[.messages[]? | select(.role == "user")] | length' "$session_file" 2>/dev/null || echo "?")
      local assistant_messages
      assistant_messages=$(jq '[.messages[]? | select(.role == "assistant")] | length' "$session_file" 2>/dev/null || echo "?")

      echo "## Metadata"
      echo ""
      echo "- Total messages: ${total_messages}"
      echo "- User messages: ${user_messages}"
      echo "- Assistant messages: ${assistant_messages}"
      echo ""

      # First user messages
      echo "## First User Messages"
      echo ""
      extract_messages "$session_file" "user" "first"

      # Last user messages
      echo "## Last User Messages"
      echo ""
      extract_messages "$session_file" "user" "last"

      # First assistant messages
      echo "## First Assistant Messages"
      echo ""
      extract_messages "$session_file" "assistant" "first"

      # Last assistant messages
      echo "## Last Assistant Messages"
      echo ""
      extract_messages "$session_file" "assistant" "last"
    else
      # Plain text fallback
      echo "## Content (head)"
      echo ""
      echo '```'
      head -50 "$session_file"
      echo '```'
      echo ""
      echo "## Content (tail)"
      echo ""
      echo '```'
      tail -50 "$session_file"
      echo '```'
    fi
  } > "$summary_file"

  echo "  SAVED: ${session_id} → ${summary_file}"
}

# --- Main --------------------------------------------------------------------
echo "Session Context Summarizer"
echo "Threshold: ${CRITICAL_THRESHOLD}KB | Mode: ${MODE}"
echo ""

if [[ "$MODE" == "single" ]]; then
  # Find the specific session file
  found_file=""
  while IFS= read -r f; do
    if [[ "$(basename "$f")" == *"${TARGET_SESSION}"* ]]; then
      found_file="$f"
      break
    fi
  done < <(find "$SESSION_DIR" -type f \( -name '*.json' -o -name '*.jsonl' \) 2>/dev/null)

  if [[ -z "$found_file" ]]; then
    echo "ERROR: Session '${TARGET_SESSION}' not found in ${SESSION_DIR}"
    exit 1
  fi

  summarize_session "$found_file"
else
  # Find all oversized sessions
  oversized=0
  summarized=0
  skipped=0

  if [[ ! -d "$SESSION_DIR" ]]; then
    echo "Session directory not found: ${SESSION_DIR}"
    exit 1
  fi

  while IFS= read -r session_file; do
    file_size=$(wc -c < "$session_file" | tr -d ' ')
    if (( file_size >= threshold_bytes )); then
      (( oversized++ )) || true
      session_id=$(basename "$session_file" | sed 's/\.[^.]*$//')
      if is_already_summarized "$session_id"; then
        (( skipped++ )) || true
        continue
      fi
      summarize_session "$session_file"
      (( summarized++ )) || true
    fi
  done < <(find "$SESSION_DIR" -type f \( -name '*.json' -o -name '*.jsonl' \) 2>/dev/null)

  echo ""
  echo "Results: ${oversized} oversized, ${summarized} summarized, ${skipped} already done"
fi
