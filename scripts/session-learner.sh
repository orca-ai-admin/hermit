#!/usr/bin/env bash
# session-learner.sh — Extract learning patterns from recent memory and sessions.
#
# Usage: session-learner.sh [--days N] [--dry-run] [--patterns-file /path]
#
# Scans daily memory files for corrections, successes, and error resolutions.
# Outputs findings grouped by type and optionally appends to a patterns file.

set -euo pipefail

# --- Configuration -----------------------------------------------------------
WORKSPACE="${HERMIT_WORKSPACE:-${PWD}}"
MEMORY_DIR="${HERMIT_MEMORY_DIR:-${WORKSPACE}/memory}"
PATTERNS_FILE="${HERMIT_PATTERNS_FILE:-${WORKSPACE}/memory/learned-patterns.md}"
DAYS="${HERMIT_LEARNER_DAYS:-3}"
DRY_RUN=false

# --- Argument parsing --------------------------------------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --days|-d)          DAYS="$2"; shift 2 ;;
    --dry-run|-n)       DRY_RUN=true; shift ;;
    --patterns-file|-p) PATTERNS_FILE="$2"; shift 2 ;;
    --help|-h)
      echo "Usage: $(basename "$0") [--days N] [--dry-run] [--patterns-file /path]"
      echo ""
      echo "Extracts learning patterns from recent daily memory files."
      echo ""
      echo "Options:"
      echo "  --days N          Lookback period (default: ${DAYS})"
      echo "  --dry-run         Show findings without writing to patterns file"
      echo "  --patterns-file   Output file for accumulated patterns"
      echo ""
      echo "Env vars:"
      echo "  HERMIT_MEMORY_DIR     Memory directory"
      echo "  HERMIT_PATTERNS_FILE  Patterns output file"
      echo "  HERMIT_LEARNER_DAYS   Lookback days"
      exit 0
      ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

# --- Helpers -----------------------------------------------------------------
date_n_days_ago() {
  local n=$1
  if date -v-${n}d +%Y-%m-%d &>/dev/null; then
    date -v-${n}d +%Y-%m-%d
  else
    date -d "${n} days ago" +%Y-%m-%d
  fi
}

today=$(date +%Y-%m-%d)

# --- Scan memory files -------------------------------------------------------
corrections=()
successes=()
error_resolutions=()
capabilities=()
files_scanned=0

for i in $(seq 0 "$DAYS"); do
  check_date=$(date_n_days_ago "$i")
  mem_file="${MEMORY_DIR}/${check_date}.md"

  [[ -f "$mem_file" ]] || continue
  (( files_scanned++ )) || true

  # Extract correction lines
  while IFS= read -r line; do
    [[ -n "$line" ]] && corrections+=("[${check_date}] ${line}")
  done < <(grep -iE '(correction|mistake|wrong|should have|lesson learned|don.t|never again|bug.?fix)' "$mem_file" 2>/dev/null | head -20 || true)

  # Extract success lines
  while IFS= read -r line; do
    [[ -n "$line" ]] && successes+=("[${check_date}] ${line}")
  done < <(grep -iE '(success|completed|shipped|deployed|working|resolved|achieved|delivered)' "$mem_file" 2>/dev/null | head -20 || true)

  # Extract error resolution lines
  while IFS= read -r line; do
    [[ -n "$line" ]] && error_resolutions+=("[${check_date}] ${line}")
  done < <(grep -iE '(fixed by|resolved by|solution was|workaround|root cause|the fix|turned out)' "$mem_file" 2>/dev/null | head -20 || true)

  # Extract new capabilities
  while IFS= read -r line; do
    [[ -n "$line" ]] && capabilities+=("[${check_date}] ${line}")
  done < <(grep -iE '(new (tool|capability|skill|access)|learned|discovered|installed|now (have|can|able))' "$mem_file" 2>/dev/null | head -20 || true)
done

# --- Output ------------------------------------------------------------------
report=""

report+="# Session Learner Report"$'\n'
report+=""$'\n'
report+="Date: ${today} | Lookback: ${DAYS} days | Files scanned: ${files_scanned}"$'\n'
report+=""$'\n'

if [[ ${#corrections[@]} -gt 0 ]]; then
  report+="## 🔴 Corrections (${#corrections[@]})"$'\n'
  report+=""$'\n'
  for item in "${corrections[@]}"; do
    report+="- ${item}"$'\n'
  done
  report+=""$'\n'
fi

if [[ ${#error_resolutions[@]} -gt 0 ]]; then
  report+="## 🔧 Error Resolutions (${#error_resolutions[@]})"$'\n'
  report+=""$'\n'
  for item in "${error_resolutions[@]}"; do
    report+="- ${item}"$'\n'
  done
  report+=""$'\n'
fi

if [[ ${#successes[@]} -gt 0 ]]; then
  report+="## ✅ Successes (${#successes[@]})"$'\n'
  report+=""$'\n'
  for item in "${successes[@]}"; do
    report+="- ${item}"$'\n'
  done
  report+=""$'\n'
fi

if [[ ${#capabilities[@]} -gt 0 ]]; then
  report+="## 🆕 New Capabilities (${#capabilities[@]})"$'\n'
  report+=""$'\n'
  for item in "${capabilities[@]}"; do
    report+="- ${item}"$'\n'
  done
  report+=""$'\n'
fi

total=$(( ${#corrections[@]} + ${#successes[@]} + ${#error_resolutions[@]} + ${#capabilities[@]} ))

if (( total == 0 )); then
  report+="No patterns found in the last ${DAYS} days."$'\n'
fi

echo "$report"

# --- Write to patterns file --------------------------------------------------
if ! $DRY_RUN && (( total > 0 )); then
  mkdir -p "$(dirname "$PATTERNS_FILE")"

  {
    echo ""
    echo "---"
    echo "<!-- Extracted: ${today} | Days: ${DAYS} -->"
    echo ""

    if [[ ${#corrections[@]} -gt 0 ]]; then
      echo "### Corrections (${today})"
      for item in "${corrections[@]}"; do
        echo "- ${item}"
      done
      echo ""
    fi

    if [[ ${#error_resolutions[@]} -gt 0 ]]; then
      echo "### Error Resolutions (${today})"
      for item in "${error_resolutions[@]}"; do
        echo "- ${item}"
      done
      echo ""
    fi

    if [[ ${#successes[@]} -gt 0 ]]; then
      echo "### Successes (${today})"
      for item in "${successes[@]}"; do
        echo "- ${item}"
      done
      echo ""
    fi

    if [[ ${#capabilities[@]} -gt 0 ]]; then
      echo "### New Capabilities (${today})"
      for item in "${capabilities[@]}"; do
        echo "- ${item}"
      done
      echo ""
    fi
  } >> "$PATTERNS_FILE"

  echo "Appended ${total} findings to: ${PATTERNS_FILE}"
else
  if $DRY_RUN; then
    echo "(dry run — nothing written)"
  fi
fi
