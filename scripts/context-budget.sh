#!/usr/bin/env bash
# context-budget.sh — Measure bootstrap context file sizes, estimate tokens, flag bloat.
#
# Usage: context-budget.sh [--verbose] [--workspace /path]
#
# Env: HERMIT_WORKSPACE overrides default workspace path.

set -euo pipefail

# --- Configuration -----------------------------------------------------------
WORKSPACE="${HERMIT_WORKSPACE:-${PWD}}"
VERBOSE=false

WARN_FILE=8000      # bytes — per-file warning threshold
CRIT_FILE=15000     # bytes — per-file critical threshold
TOTAL_WARN=50000    # bytes — total warning threshold
TOTAL_CRIT=80000    # bytes — total critical threshold

BOOTSTRAP_FILES=(
  AGENTS.md
  SOUL.md
  USER.md
  IDENTITY.md
  TOOLS.md
  MEMORY.md
  HEARTBEAT.md
)

# --- Colors ------------------------------------------------------------------
if [[ -t 1 ]]; then
  RED='\033[0;31m'; YELLOW='\033[0;33m'; GREEN='\033[0;32m'
  CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'
else
  RED=''; YELLOW=''; GREEN=''; CYAN=''; BOLD=''; RESET=''
fi

# --- Argument parsing --------------------------------------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --verbose|-v) VERBOSE=true; shift ;;
    --workspace|-w) WORKSPACE="$2"; shift 2 ;;
    --help|-h)
      echo "Usage: $(basename "$0") [--verbose] [--workspace /path]"
      echo ""
      echo "Measures bootstrap context file sizes, estimates tokens, and flags bloat."
      echo ""
      echo "Options:"
      echo "  --verbose, -v      Show section breakdown of large files"
      echo "  --workspace, -w    Set workspace path (default: \$HERMIT_WORKSPACE or \$PWD)"
      echo ""
      echo "Thresholds:"
      echo "  Per-file warning:  ${WARN_FILE} bytes"
      echo "  Per-file critical: ${CRIT_FILE} bytes"
      echo "  Total warning:     ${TOTAL_WARN} bytes"
      echo "  Total critical:    ${TOTAL_CRIT} bytes"
      exit 0
      ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

# --- Helpers -----------------------------------------------------------------
estimate_tokens() {
  local file="$1"
  if [[ -f "$file" ]]; then
    local words
    words=$(wc -w < "$file" | tr -d ' ')
    echo $(( words * 13 / 10 ))  # words × 1.3
  else
    echo 0
  fi
}

file_status() {
  local size=$1
  if (( size >= CRIT_FILE )); then
    printf "${RED}CRITICAL${RESET}"
  elif (( size >= WARN_FILE )); then
    printf "${YELLOW}WARNING${RESET}"
  else
    printf "${GREEN}OK${RESET}"
  fi
}

show_sections() {
  local file="$1"
  [[ -f "$file" ]] || return
  # Extract ## headings and count lines between them
  local current_section="(preamble)"
  local line_count=0
  while IFS= read -r line; do
    if [[ "$line" =~ ^##[[:space:]]+(.*) ]]; then
      if (( line_count > 0 )); then
        printf "    %-40s %d lines\n" "$current_section" "$line_count"
      fi
      current_section="${BASH_REMATCH[1]}"
      line_count=0
    else
      (( line_count++ )) || true
    fi
  done < "$file"
  if (( line_count > 0 )); then
    printf "    %-40s %d lines\n" "$current_section" "$line_count"
  fi
}

# --- Main --------------------------------------------------------------------
echo -e "${BOLD}Context Budget Report${RESET}"
echo -e "Workspace: ${CYAN}${WORKSPACE}${RESET}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

total_bytes=0
total_tokens=0
issues=()
recommendations=()

printf "%-20s %8s %8s %s\n" "FILE" "BYTES" "~TOKENS" "STATUS"
printf "%-20s %8s %8s %s\n" "----" "-----" "-------" "------"

for file in "${BOOTSTRAP_FILES[@]}"; do
  filepath="${WORKSPACE}/${file}"
  if [[ -f "$filepath" ]]; then
    size=$(wc -c < "$filepath" | tr -d ' ')
    tokens=$(estimate_tokens "$filepath")
    status=$(file_status "$size")
    printf "%-20s %8d %8d %b\n" "$file" "$size" "$tokens" "$status"

    total_bytes=$(( total_bytes + size ))
    total_tokens=$(( total_tokens + tokens ))

    if (( size >= CRIT_FILE )); then
      issues+=("${file} is ${size} bytes (critical threshold: ${CRIT_FILE})")
      recommendations+=("Split or trim ${file} — it's consuming excessive context budget")
    elif (( size >= WARN_FILE )); then
      issues+=("${file} is ${size} bytes (warning threshold: ${WARN_FILE})")
      recommendations+=("Consider trimming ${file} to stay under ${WARN_FILE} bytes")
    fi

    if $VERBOSE && (( size >= WARN_FILE )); then
      echo -e "  ${CYAN}Section breakdown:${RESET}"
      show_sections "$filepath"
    fi
  else
    printf "%-20s %8s %8s %s\n" "$file" "—" "—" "not found"
  fi
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Total status
total_status="${GREEN}OK${RESET}"
if (( total_bytes >= TOTAL_CRIT )); then
  total_status="${RED}CRITICAL${RESET}"
elif (( total_bytes >= TOTAL_WARN )); then
  total_status="${YELLOW}WARNING${RESET}"
fi

printf "%-20s %8d %8d %b\n" "TOTAL" "$total_bytes" "$total_tokens" "$total_status"

if (( total_bytes >= TOTAL_CRIT )); then
  issues+=("Total bootstrap context is ${total_bytes} bytes (critical: ${TOTAL_CRIT})")
  recommendations+=("Aggressively trim bootstrap files — total context is critically large")
elif (( total_bytes >= TOTAL_WARN )); then
  issues+=("Total bootstrap context is ${total_bytes} bytes (warning: ${TOTAL_WARN})")
  recommendations+=("Review bootstrap files for content that could move to on-demand loading")
fi

# Memory directory
echo ""
echo -e "${BOLD}Memory Directory${RESET}"
memory_dir="${WORKSPACE}/memory"
if [[ -d "$memory_dir" ]]; then
  mem_files=$(find "$memory_dir" -type f -name '*.md' 2>/dev/null | wc -l | tr -d ' ')
  mem_size=$(du -sh "$memory_dir" 2>/dev/null | cut -f1)
  echo "  Files: ${mem_files}"
  echo "  Total size: ${mem_size}"

  if (( mem_files > 90 )); then
    recommendations+=("Memory directory has ${mem_files} files — consider archiving old entries")
  fi
else
  echo "  (not found)"
fi

# Recommendations
echo ""
if [[ ${#recommendations[@]} -gt 0 ]]; then
  echo -e "${BOLD}Recommendations${RESET}"
  for rec in "${recommendations[@]}"; do
    echo -e "  ${YELLOW}→${RESET} ${rec}"
  done
else
  echo -e "${GREEN}All files within budget. No recommendations.${RESET}"
fi

# Exit code
if (( total_bytes >= TOTAL_CRIT )); then
  exit 2
elif (( total_bytes >= TOTAL_WARN )); then
  exit 1
else
  exit 0
fi
