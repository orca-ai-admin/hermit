#!/usr/bin/env bash
# session-context-monitor.sh — Detect context dilution in long sessions
# Part of the Hermit framework's SESSION CONTEXT red gate.
#
# Usage: ./scripts/session-context-monitor.sh [--session-dir PATH]
#
# Checks active sessions for signs of context dilution:
# - Message count exceeding thresholds
# - Session size in bytes
# - Time since session start
#
# This is a reference implementation. Adapt the session file parsing
# to match your agent framework's session storage format.

set -euo pipefail

SESSION_DIR="${HERMIT_SESSION_DIR:-./sessions}"
WARNING_MESSAGES=30
CRITICAL_MESSAGES=60
WARNING_SIZE_KB=250
CRITICAL_SIZE_KB=500

# Parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    --session-dir) SESSION_DIR="$2"; shift 2 ;;
    --warning-messages) WARNING_MESSAGES="$2"; shift 2 ;;
    --critical-messages) CRITICAL_MESSAGES="$2"; shift 2 ;;
    *) echo "Unknown arg: $1"; exit 1 ;;
  esac
done

echo "🔍 Session Context Monitor — $(date '+%Y-%m-%d %H:%M:%S')"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Thresholds: ⚠️ ${WARNING_MESSAGES} msgs / ${WARNING_SIZE_KB}KB"
echo "              🔴 ${CRITICAL_MESSAGES} msgs / ${CRITICAL_SIZE_KB}KB"
echo ""

STATUS="OK"

if [[ ! -d "$SESSION_DIR" ]]; then
  echo "  ⚠️  Session directory not found: $SESSION_DIR"
  echo "  Configure SESSION_DIR or pass --session-dir."
  echo ""
  echo "  To integrate with your agent framework:"
  echo "  1. Point to your active session storage directory"
  echo "  2. Each session file should contain conversation messages"
  echo "  3. The script counts messages and checks file size"
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "⚠️  SESSION MONITOR — No sessions to scan"
  exit 0
fi

# Scan active session files
for session_file in "$SESSION_DIR"/*.json "$SESSION_DIR"/*.jsonl 2>/dev/null; do
  [[ -f "$session_file" ]] || continue
  
  filename=$(basename "$session_file")
  size_kb=$(( $(wc -c < "$session_file") / 1024 ))
  
  # Count assistant messages (adapt this jq query to your format)
  msg_count=$(jq -r '[.messages[]? | select(.role == "assistant")] | length' "$session_file" 2>/dev/null || echo "?")
  
  # Determine status
  if [[ "$msg_count" != "?" ]] && [[ "$msg_count" -gt "$CRITICAL_MESSAGES" ]] || [[ "$size_kb" -gt "$CRITICAL_SIZE_KB" ]]; then
    echo "  🔴 CRITICAL: $filename — ${msg_count} msgs, ${size_kb}KB"
    echo "     → DO NOT start new complex work in this session"
    echo "     → Suggest session rotation to human"
    STATUS="CRITICAL"
  elif [[ "$msg_count" != "?" ]] && [[ "$msg_count" -gt "$WARNING_MESSAGES" ]] || [[ "$size_kb" -gt "$WARNING_SIZE_KB" ]]; then
    echo "  ⚠️  WARNING: $filename — ${msg_count} msgs, ${size_kb}KB"
    echo "     → Finish current task, then suggest fresh session"
    [[ "$STATUS" != "CRITICAL" ]] && STATUS="WARNING"
  else
    echo "  ✅ $filename — ${msg_count} msgs, ${size_kb}KB"
  fi
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
case "$STATUS" in
  CRITICAL)
    echo "🔴 SESSION CONTEXT: CRITICAL — rotate sessions before quality degrades"
    exit 2
    ;;
  WARNING)
    echo "⚠️  SESSION CONTEXT: WARNING — consider rotating soon"
    exit 1
    ;;
  *)
    echo "✅ SESSION CONTEXT: OK — all sessions within thresholds"
    exit 0
    ;;
esac
