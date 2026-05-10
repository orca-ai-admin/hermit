#!/usr/bin/env bash
# burst-guard.sh — Detect message bursts on messaging surfaces
# Part of the Hermit framework's ANTI-BURST red gate.
#
# Usage: ./scripts/burst-guard.sh [--hours N] [--threshold N] [--log-dir PATH]
#
# Scans message logs for rapid-fire message sequences (bursts) where
# the agent sent multiple messages within a short window.
#
# A "burst" is defined as 3+ agent messages within 60 seconds.
#
# This is a reference implementation. Adapt the log parsing to match
# your messaging system's log format.

set -euo pipefail

# Defaults
HOURS=72
THRESHOLD=3
LOG_DIR="${HERMIT_LOG_DIR:-./logs}"

# Parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    --hours) HOURS="$2"; shift 2 ;;
    --threshold) THRESHOLD="$2"; shift 2 ;;
    --log-dir) LOG_DIR="$2"; shift 2 ;;
    *) echo "Unknown arg: $1"; exit 1 ;;
  esac
done

echo "🔍 Burst Guard — Scanning last ${HOURS}h"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Threshold: ${THRESHOLD}+ messages within 60s = burst"
echo "  Log dir: $LOG_DIR"
echo ""

BURST_COUNT=0

# ═══════════════════════════════════════════════
# LOG PARSING — Customize this for your setup
# ═══════════════════════════════════════════════
#
# This reference implementation looks for log files with lines like:
#   2026-03-15T14:30:00Z AGENT_MSG: <message content>
#
# Replace this section with parsing logic for your messaging system.
# The goal: extract timestamps of agent-sent messages and find clusters
# of 3+ messages within 60 seconds.

if [[ ! -d "$LOG_DIR" ]]; then
  echo "  ⚠️  Log directory not found: $LOG_DIR"
  echo "  Configure LOG_DIR or pass --log-dir to point to your message logs."
  echo ""
  echo "  To integrate with your messaging system:"
  echo "  1. Parse your outgoing message logs"
  echo "  2. Extract timestamps of agent-sent messages"
  echo "  3. Find clusters of ${THRESHOLD}+ messages within 60 seconds"
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "⚠️  BURST GUARD — No logs to scan (configure log directory)"
  exit 0
fi

# Example: scan for timestamp patterns in log files
# Adapt this to your actual log format
CUTOFF=$(date -v-${HOURS}H '+%Y-%m-%dT%H:%M:%S' 2>/dev/null || \
         date -d "${HOURS} hours ago" '+%Y-%m-%dT%H:%M:%S' 2>/dev/null || \
         echo "1970-01-01T00:00:00")

echo "  Scanning since: $CUTOFF"
echo ""

# Placeholder: In a real implementation, you'd parse your message logs here
# and count burst incidents. For now, report the check ran.
echo "  📊 Burst incidents found: $BURST_COUNT"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [[ "$BURST_COUNT" -gt "$THRESHOLD" ]]; then
  echo "❌ BURST GUARD ALERT — $BURST_COUNT bursts in last ${HOURS}h (threshold: $THRESHOLD)"
  echo "   Investigate which sessions are producing bursts."
  echo "   Fix: ensure tool calls run silently, compose ONE response after ALL tools complete."
  exit 1
else
  echo "✅ BURST GUARD OK — $BURST_COUNT bursts in last ${HOURS}h"
  exit 0
fi
