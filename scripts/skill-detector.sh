#!/usr/bin/env bash
# skill-detector.sh — Identify repeated patterns worth extracting into skills.
#
# Usage: skill-detector.sh [--days N] [--sessions-dir /path] [--top N]
#
# Scans session files for repeated tool sequences, repeated web searches,
# and most-used tools. Outputs a markdown report.

set -euo pipefail

# --- Configuration -----------------------------------------------------------
SESSIONS_DIR="${HERMIT_SESSIONS_DIR:-${HOME}/.openclaw/sessions}"
DAYS="${HERMIT_DETECTOR_DAYS:-7}"
TOP_N=10

# --- Argument parsing --------------------------------------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --days|-d)         DAYS="$2"; shift 2 ;;
    --sessions-dir|-s) SESSIONS_DIR="$2"; shift 2 ;;
    --top|-t)          TOP_N="$2"; shift 2 ;;
    --help|-h)
      echo "Usage: $(basename "$0") [--days N] [--sessions-dir /path] [--top N]"
      echo ""
      echo "Identifies repeated patterns worth extracting into skills."
      echo ""
      echo "Options:"
      echo "  --days N          Lookback period (default: ${DAYS})"
      echo "  --sessions-dir    Session log directory"
      echo "  --top N           Top N items to show (default: ${TOP_N})"
      echo ""
      echo "Env vars:"
      echo "  HERMIT_SESSIONS_DIR     Session log directory"
      echo "  HERMIT_DETECTOR_DAYS    Lookback days"
      exit 0
      ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

# --- Dependency check --------------------------------------------------------
if ! command -v jq &>/dev/null; then
  echo "ERROR: jq is required but not installed."
  exit 1
fi

# --- Helpers -----------------------------------------------------------------
TMPDIR_WORK=$(mktemp -d)
trap 'rm -rf "$TMPDIR_WORK"' EXIT

# --- Find recent session files -----------------------------------------------
if [[ ! -d "$SESSIONS_DIR" ]]; then
  echo "Session directory not found: ${SESSIONS_DIR}"
  exit 1
fi

session_files=()
while IFS= read -r f; do
  session_files+=("$f")
done < <(find "$SESSIONS_DIR" -type f \( -name '*.json' -o -name '*.jsonl' \) -mtime "-${DAYS}" 2>/dev/null)

total_sessions=${#session_files[@]}

echo "# Skill Detector Report"
echo ""
echo "- Sessions scanned: ${total_sessions}"
echo "- Lookback: ${DAYS} days"
echo "- Sessions dir: \`${SESSIONS_DIR}\`"
echo ""

if (( total_sessions == 0 )); then
  echo "No session files found in the last ${DAYS} days."
  exit 0
fi

# --- 1. Most-used tools ------------------------------------------------------
echo "## 🔧 Most-Used Tools"
echo ""

tool_counts="${TMPDIR_WORK}/tool_counts.txt"
> "$tool_counts"

for session_file in "${session_files[@]}"; do
  # Extract tool names from assistant messages with tool_calls
  jq -r '
    .messages[]? |
    select(.role == "assistant") |
    .tool_calls[]? .function.name // empty
  ' "$session_file" 2>/dev/null >> "$tool_counts" || true

  # Also try content-based tool detection
  jq -r '
    .messages[]? |
    select(.role == "assistant") |
    .content // "" |
    capture("(?<tool>read|write|edit|exec|web_search|web_fetch|image|process|message)"; "g") |
    .tool
  ' "$session_file" 2>/dev/null >> "$tool_counts" || true
done

if [[ -s "$tool_counts" ]]; then
  echo "| Tool | Uses |"
  echo "|------|------|"
  sort "$tool_counts" | uniq -c | sort -rn | head -"$TOP_N" | while read -r count tool; do
    echo "| ${tool} | ${count} |"
  done
  echo ""
else
  echo "No tool usage data found."
  echo ""
fi

# --- 2. Repeated tool sequences (3-tool windows) -----------------------------
echo "## 🔄 Repeated Tool Sequences (3-tool windows)"
echo ""

sequence_file="${TMPDIR_WORK}/sequences.txt"
> "$sequence_file"

for session_file in "${session_files[@]}"; do
  # Extract ordered tool names per session
  tools_in_session="${TMPDIR_WORK}/session_tools.txt"
  jq -r '
    [.messages[]? | select(.role == "assistant") | .tool_calls[]? .function.name // empty] | .[]
  ' "$session_file" 2>/dev/null > "$tools_in_session" || continue

  # Generate 3-tool sliding windows
  mapfile -t tools < "$tools_in_session"
  for (( i = 0; i + 2 < ${#tools[@]}; i++ )); do
    echo "${tools[$i]} → ${tools[$((i+1))]} → ${tools[$((i+2))]}" >> "$sequence_file"
  done
done

if [[ -s "$sequence_file" ]]; then
  # Find sequences that appear 3+ times
  repeated=$(sort "$sequence_file" | uniq -c | sort -rn | awk '$1 >= 3')
  if [[ -n "$repeated" ]]; then
    echo "Sequences appearing 3+ times:"
    echo ""
    echo "| Sequence | Count |"
    echo "|----------|-------|"
    echo "$repeated" | head -"$TOP_N" | while read -r count seq; do
      echo "| ${seq} | ${count} |"
    done
    echo ""
    echo "**Skill candidates**: Repeated sequences suggest automatable workflows."
  else
    echo "No tool sequences repeated 3+ times."
  fi
else
  echo "No tool sequence data found."
fi
echo ""

# --- 3. Repeated web searches ------------------------------------------------
echo "## 🔍 Repeated Web Searches"
echo ""

search_file="${TMPDIR_WORK}/searches.txt"
> "$search_file"

for session_file in "${session_files[@]}"; do
  # Extract web_search queries
  jq -r '
    .messages[]? |
    select(.role == "assistant") |
    .tool_calls[]? |
    select(.function.name == "web_search") |
    .function.arguments | fromjson? | .query // empty
  ' "$session_file" 2>/dev/null >> "$search_file" || true
done

if [[ -s "$search_file" ]]; then
  # Normalize and find duplicates (lowercase, trim)
  repeated_searches=$(awk '{print tolower($0)}' "$search_file" | sort | uniq -c | sort -rn | awk '$1 >= 2')
  if [[ -n "$repeated_searches" ]]; then
    echo "Searches performed 2+ times:"
    echo ""
    echo "| Query | Count |"
    echo "|-------|-------|"
    echo "$repeated_searches" | head -"$TOP_N" | while IFS= read -r line; do
      count=$(echo "$line" | awk '{print $1}')
      query=$(echo "$line" | sed 's/^[[:space:]]*[0-9]*[[:space:]]*//')
      echo "| ${query} | ${count} |"
    done
    echo ""
    echo "**Skill candidates**: Repeated searches suggest knowledge gaps worth caching."
  else
    echo "No repeated web searches found."
  fi
else
  echo "No web search data found."
fi
echo ""

# --- 4. Session statistics ----------------------------------------------------
echo "## 📊 Session Statistics"
echo ""

total_messages=0
total_tool_calls=0
longest_session=0
longest_session_id=""

for session_file in "${session_files[@]}"; do
  msg_count=$(jq '[.messages[]?] | length' "$session_file" 2>/dev/null || echo 0)
  tool_count=$(jq '[.messages[]? | .tool_calls[]?] | length' "$session_file" 2>/dev/null || echo 0)

  total_messages=$(( total_messages + msg_count ))
  total_tool_calls=$(( total_tool_calls + tool_count ))

  if (( msg_count > longest_session )); then
    longest_session=$msg_count
    longest_session_id=$(basename "$session_file")
  fi
done

echo "| Metric | Value |"
echo "|--------|-------|"
echo "| Total sessions | ${total_sessions} |"
echo "| Total messages | ${total_messages} |"
echo "| Total tool calls | ${total_tool_calls} |"
echo "| Longest session | ${longest_session} msgs (\`${longest_session_id}\`) |"
if (( total_sessions > 0 )); then
  echo "| Avg messages/session | $(( total_messages / total_sessions )) |"
  echo "| Avg tool calls/session | $(( total_tool_calls / total_sessions )) |"
fi
echo ""

echo "---"
echo "Report generated: $(date '+%Y-%m-%d %H:%M:%S %Z')"
