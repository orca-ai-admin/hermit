#!/usr/bin/env bash
# cron-health.sh — Check cron job health from a JSON state file.
#
# Usage: cron-health.sh [--state /path/to/state.json] [--config /path/to/config.json]
#
# Expects state JSON with structure:
#   { "job_name": { "last_run": "ISO8601", "last_status": "ok|error|timeout",
#                   "consecutive_errors": N, "last_error": "message" }, ... }
#
# Exit 0 if healthy, exit 1 if issues found.

set -euo pipefail

# --- Configuration -----------------------------------------------------------
WORKSPACE="${HERMIT_WORKSPACE:-${PWD}}"
CRON_STATE="${HERMIT_CRON_STATE:-${WORKSPACE}/state/cron-state.json}"
CRON_CONFIG="${HERMIT_CRON_CONFIG:-${WORKSPACE}/config/cron-config.json}"

STALE_HOURS=48              # hours before a job is considered stale
ERROR_THRESHOLD=3           # consecutive errors before flagging

# --- Argument parsing --------------------------------------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --state|-s)  CRON_STATE="$2"; shift 2 ;;
    --config|-c) CRON_CONFIG="$2"; shift 2 ;;
    --stale-hours) STALE_HOURS="$2"; shift 2 ;;
    --help|-h)
      echo "Usage: $(basename "$0") [--state path] [--config path] [--stale-hours N]"
      echo ""
      echo "Checks cron job health from a JSON state file."
      echo ""
      echo "Env vars:"
      echo "  HERMIT_CRON_STATE   Path to cron state JSON"
      echo "  HERMIT_CRON_CONFIG  Path to cron config JSON"
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

# --- Main --------------------------------------------------------------------
issues=()
warnings=()

if [[ ! -f "$CRON_STATE" ]]; then
  echo "## Cron Health Report"
  echo ""
  echo "**State file not found:** \`${CRON_STATE}\`"
  echo ""
  echo "No cron jobs to check. Create the state file or set HERMIT_CRON_STATE."
  exit 0
fi

now_epoch=$(date +%s)
stale_seconds=$(( STALE_HOURS * 3600 ))

echo "## Cron Health Report"
echo ""
echo "State file: \`${CRON_STATE}\`"
echo "Checked: $(date '+%Y-%m-%d %H:%M:%S %Z')"
echo ""

job_names=$(jq -r 'keys[]' "$CRON_STATE" 2>/dev/null)

if [[ -z "$job_names" ]]; then
  echo "No jobs found in state file."
  exit 0
fi

echo "| Job | Last Run | Status | Errors | Notes |"
echo "|-----|----------|--------|--------|-------|"

for job in $job_names; do
  last_run=$(jq -r --arg j "$job" '.[$j].last_run // "never"' "$CRON_STATE")
  last_status=$(jq -r --arg j "$job" '.[$j].last_status // "unknown"' "$CRON_STATE")
  consec_errors=$(jq -r --arg j "$job" '.[$j].consecutive_errors // 0' "$CRON_STATE")
  last_error=$(jq -r --arg j "$job" '.[$j].last_error // ""' "$CRON_STATE")

  notes=""
  job_ok=true

  # Check staleness
  if [[ "$last_run" != "never" && "$last_run" != "null" ]]; then
    # Try to parse the date
    if run_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%S" "${last_run%%[.Z+]*}" +%s 2>/dev/null) || \
       run_epoch=$(date -d "${last_run}" +%s 2>/dev/null); then
      age_hours=$(( (now_epoch - run_epoch) / 3600 ))
      if (( now_epoch - run_epoch > stale_seconds )); then
        notes="⚠️ STALE (${age_hours}h ago)"
        issues+=("${job}: stale — last ran ${age_hours}h ago (threshold: ${STALE_HOURS}h)")
        job_ok=false
      fi
    else
      notes="⚠️ unparseable date"
      warnings+=("${job}: could not parse last_run date '${last_run}'")
    fi
  elif [[ "$last_run" == "never" ]]; then
    notes="⚠️ never run"
    warnings+=("${job}: has never run")
  fi

  # Check consecutive errors
  if (( consec_errors >= ERROR_THRESHOLD )); then
    notes="${notes:+${notes} | }🔴 ${consec_errors} consecutive errors"
    issues+=("${job}: ${consec_errors} consecutive errors (threshold: ${ERROR_THRESHOLD})")
    job_ok=false
  elif (( consec_errors > 0 )); then
    notes="${notes:+${notes} | }⚠️ ${consec_errors} error(s)"
    warnings+=("${job}: ${consec_errors} recent error(s)")
  fi

  # Check for timeout specifically
  if [[ "$last_status" == "timeout" ]]; then
    notes="${notes:+${notes} | }⏱️ TIMEOUT"
    issues+=("${job}: last run timed out")
    job_ok=false
  fi

  # Check error message
  if [[ -n "$last_error" && "$last_error" != "null" ]]; then
    notes="${notes:+${notes} | }${last_error}"
  fi

  if $job_ok && [[ -z "$notes" ]]; then
    notes="✅"
  fi

  # Status emoji
  case "$last_status" in
    ok)      status_display="✅ ok" ;;
    error)   status_display="❌ error" ;;
    timeout) status_display="⏱️ timeout" ;;
    *)       status_display="❓ ${last_status}" ;;
  esac

  echo "| ${job} | ${last_run} | ${status_display} | ${consec_errors} | ${notes} |"
done

echo ""

# Summary
if [[ ${#issues[@]} -gt 0 ]]; then
  echo "### Issues (${#issues[@]})"
  echo ""
  for issue in "${issues[@]}"; do
    echo "- 🔴 ${issue}"
  done
  echo ""
fi

if [[ ${#warnings[@]} -gt 0 ]]; then
  echo "### Warnings (${#warnings[@]})"
  echo ""
  for warning in "${warnings[@]}"; do
    echo "- ⚠️ ${warning}"
  done
  echo ""
fi

if [[ ${#issues[@]} -eq 0 && ${#warnings[@]} -eq 0 ]]; then
  echo "**All cron jobs healthy.** ✅"
fi

# Exit code
if [[ ${#issues[@]} -gt 0 ]]; then
  exit 1
else
  exit 0
fi
