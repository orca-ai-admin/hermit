#!/usr/bin/env bash
# evolution-engine.sh — Self-improvement cycle: reflect, audit, metrics.
#
# Usage: evolution-engine.sh [--reflect] [--audit] [--metrics] [--full] [--days N]
#
# Modes:
#   --reflect   Scan daily memory for corrections, successes, new capabilities
#   --audit     Check cron health, staleness, disk usage — output JSON
#   --metrics   Count corrections, experiments, patterns in last N days
#   --full      Run all three modes
#
# All paths configurable via env vars or variables below.

set -euo pipefail

# --- Configuration -----------------------------------------------------------
WORKSPACE="${HERMIT_WORKSPACE:-${PWD}}"
MEMORY_DIR="${HERMIT_MEMORY_DIR:-${WORKSPACE}/memory}"
METRICS_DIR="${HERMIT_METRICS_DIR:-${WORKSPACE}/metrics}"
SCRIPTS_DIR="${HERMIT_SCRIPTS_DIR:-${WORKSPACE}/scripts}"
DAYS="${HERMIT_EVOLUTION_DAYS:-7}"

# --- Argument parsing --------------------------------------------------------
MODE_REFLECT=false
MODE_AUDIT=false
MODE_METRICS=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --reflect)  MODE_REFLECT=true; shift ;;
    --audit)    MODE_AUDIT=true; shift ;;
    --metrics)  MODE_METRICS=true; shift ;;
    --full)     MODE_REFLECT=true; MODE_AUDIT=true; MODE_METRICS=true; shift ;;
    --days)     DAYS="$2"; shift 2 ;;
    --help|-h)
      echo "Usage: $(basename "$0") [--reflect] [--audit] [--metrics] [--full] [--days N]"
      echo ""
      echo "Self-improvement cycle engine."
      echo ""
      echo "Modes:"
      echo "  --reflect   Scan memory for corrections, successes, capabilities"
      echo "  --audit     System health check (JSON output)"
      echo "  --metrics   Count patterns in last N days (default: 7)"
      echo "  --full      Run all modes"
      echo ""
      echo "Env vars:"
      echo "  HERMIT_WORKSPACE       Workspace root"
      echo "  HERMIT_MEMORY_DIR      Memory directory"
      echo "  HERMIT_METRICS_DIR     Metrics output directory"
      echo "  HERMIT_EVOLUTION_DAYS  Lookback days (default: 7)"
      exit 0
      ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

# Default to --full if no mode specified
if ! $MODE_REFLECT && ! $MODE_AUDIT && ! $MODE_METRICS; then
  MODE_REFLECT=true; MODE_AUDIT=true; MODE_METRICS=true
fi

# --- Helpers -----------------------------------------------------------------
date_n_days_ago() {
  local n=$1
  if date -v-${n}d +%Y-%m-%d &>/dev/null; then
    date -v-${n}d +%Y-%m-%d  # macOS
  else
    date -d "${n} days ago" +%Y-%m-%d  # GNU
  fi
}

today=$(date +%Y-%m-%d)

# --- REFLECT -----------------------------------------------------------------
do_reflect() {
  echo "## 🔍 Reflect"
  echo ""
  echo "Scanning memory files from last ${DAYS} days..."
  echo ""

  local corrections=0 successes=0 capabilities=0 total_files=0

  for i in $(seq 0 "$DAYS"); do
    local check_date
    check_date=$(date_n_days_ago "$i")
    local mem_file="${MEMORY_DIR}/${check_date}.md"

    if [[ -f "$mem_file" ]]; then
      (( total_files++ )) || true

      # Count corrections (case-insensitive grep)
      local c
      c=$(grep -ciE '(correction|fix(ed)?|wrong|mistake|should have|lesson|bug|error|broke)' "$mem_file" 2>/dev/null || echo 0)
      corrections=$(( corrections + c ))

      # Count successes
      local s
      s=$(grep -ciE '(success|completed|shipped|deployed|done|working|fixed|resolved|achieved)' "$mem_file" 2>/dev/null || echo 0)
      successes=$(( successes + s ))

      # Count new capabilities
      local cap
      cap=$(grep -ciE '(new (tool|capability|skill|access)|learned|discovered|installed|configured|set up)' "$mem_file" 2>/dev/null || echo 0)
      capabilities=$(( capabilities + cap ))
    fi
  done

  echo "| Metric | Count |"
  echo "|--------|-------|"
  echo "| Memory files scanned | ${total_files} |"
  echo "| Correction mentions | ${corrections} |"
  echo "| Success mentions | ${successes} |"
  echo "| Capability mentions | ${capabilities} |"
  echo ""

  # Check MEMORY.md for long-term patterns
  local memory_file="${WORKSPACE}/MEMORY.md"
  if [[ -f "$memory_file" ]]; then
    local mem_size
    mem_size=$(wc -c < "$memory_file" | tr -d ' ')
    local mem_sections
    mem_sections=$(grep -c '^##' "$memory_file" 2>/dev/null || echo 0)
    echo "**MEMORY.md**: ${mem_size} bytes, ${mem_sections} sections"
  else
    echo "**MEMORY.md**: not found"
  fi
  echo ""
}

# --- AUDIT -------------------------------------------------------------------
do_audit() {
  echo "## 🔍 Audit"
  echo ""

  local audit_json="{"
  local issues=0

  # 1. Cron health
  local cron_status="ok"
  if [[ -x "${SCRIPTS_DIR}/cron-health.sh" ]]; then
    if ! "${SCRIPTS_DIR}/cron-health.sh" &>/dev/null; then
      cron_status="issues"
      (( issues++ )) || true
    fi
  else
    cron_status="not_configured"
  fi
  audit_json="${audit_json}\"cron_health\":\"${cron_status}\","

  # 2. MEMORY.md freshness
  local memory_freshness="unknown"
  local memory_file="${WORKSPACE}/MEMORY.md"
  if [[ -f "$memory_file" ]]; then
    local mod_epoch
    if mod_epoch=$(stat -f %m "$memory_file" 2>/dev/null) || \
       mod_epoch=$(stat -c %Y "$memory_file" 2>/dev/null); then
      local now_epoch
      now_epoch=$(date +%s)
      local age_hours=$(( (now_epoch - mod_epoch) / 3600 ))
      if (( age_hours > 168 )); then
        memory_freshness="stale_${age_hours}h"
        (( issues++ )) || true
      elif (( age_hours > 48 )); then
        memory_freshness="aging_${age_hours}h"
      else
        memory_freshness="fresh_${age_hours}h"
      fi
    fi
  else
    memory_freshness="missing"
    (( issues++ )) || true
  fi
  audit_json="${audit_json}\"memory_freshness\":\"${memory_freshness}\","

  # 3. Heartbeat staleness
  local heartbeat_status="unknown"
  local heartbeat_state="${WORKSPACE}/memory/heartbeat-state.json"
  if [[ -f "$heartbeat_state" ]] && command -v jq &>/dev/null; then
    local last_beat
    last_beat=$(jq -r '.last_heartbeat // "unknown"' "$heartbeat_state" 2>/dev/null)
    if [[ "$last_beat" != "unknown" && "$last_beat" != "null" ]]; then
      heartbeat_status="active"
    else
      heartbeat_status="no_data"
    fi
  elif [[ ! -f "$heartbeat_state" ]]; then
    heartbeat_status="no_state_file"
  fi
  audit_json="${audit_json}\"heartbeat\":\"${heartbeat_status}\","

  # 4. Disk usage
  local disk_usage
  disk_usage=$(du -sh "$WORKSPACE" 2>/dev/null | cut -f1 || echo "unknown")
  local memory_usage
  if [[ -d "$MEMORY_DIR" ]]; then
    memory_usage=$(du -sh "$MEMORY_DIR" 2>/dev/null | cut -f1 || echo "unknown")
  else
    memory_usage="no_dir"
  fi
  audit_json="${audit_json}\"disk_workspace\":\"${disk_usage}\",\"disk_memory\":\"${memory_usage}\","

  # 5. Daily memory file count
  local mem_file_count=0
  if [[ -d "$MEMORY_DIR" ]]; then
    mem_file_count=$(find "$MEMORY_DIR" -maxdepth 1 -name '????-??-??.md' -type f 2>/dev/null | wc -l | tr -d ' ')
  fi
  audit_json="${audit_json}\"memory_files\":${mem_file_count},"

  audit_json="${audit_json}\"issues\":${issues},\"timestamp\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}"

  echo '```json'
  if command -v jq &>/dev/null; then
    echo "$audit_json" | jq .
  else
    echo "$audit_json"
  fi
  echo '```'
  echo ""

  if (( issues > 0 )); then
    echo "**${issues} issue(s) found.** Review audit output above."
  else
    echo "**Audit clean.** ✅"
  fi
  echo ""
}

# --- METRICS -----------------------------------------------------------------
do_metrics() {
  echo "## 📊 Metrics (last ${DAYS} days)"
  echo ""

  mkdir -p "$METRICS_DIR"

  local corrections=0 experiments=0 patterns=0 sessions=0

  for i in $(seq 0 "$DAYS"); do
    local check_date
    check_date=$(date_n_days_ago "$i")
    local mem_file="${MEMORY_DIR}/${check_date}.md"

    if [[ -f "$mem_file" ]]; then
      local c
      c=$(grep -ciE '(correction|mistake|wrong|fix|lesson)' "$mem_file" 2>/dev/null || echo 0)
      corrections=$(( corrections + c ))

      local e
      e=$(grep -ciE '(experiment|exp-|test(ed|ing)|tried|attempt)' "$mem_file" 2>/dev/null || echo 0)
      experiments=$(( experiments + e ))

      local p
      p=$(grep -ciE '(pattern|recurring|repeated|always|every time)' "$mem_file" 2>/dev/null || echo 0)
      patterns=$(( patterns + p ))

      local s
      s=$(grep -ciE '(session|conversation|chat|thread)' "$mem_file" 2>/dev/null || echo 0)
      sessions=$(( sessions + s ))
    fi
  done

  local metrics_json
  metrics_json=$(cat <<EOF
{
  "period_days": ${DAYS},
  "date": "${today}",
  "corrections": ${corrections},
  "experiments": ${experiments},
  "patterns": ${patterns},
  "session_mentions": ${sessions}
}
EOF
)

  echo "| Metric | Count |"
  echo "|--------|-------|"
  echo "| Corrections | ${corrections} |"
  echo "| Experiments | ${experiments} |"
  echo "| Patterns | ${patterns} |"
  echo "| Session mentions | ${sessions} |"
  echo ""

  # Save metrics
  local metrics_file="${METRICS_DIR}/${today}-metrics.json"
  echo "$metrics_json" > "$metrics_file"
  echo "Metrics saved to: \`${metrics_file}\`"
  echo ""
}

# --- Run selected modes ------------------------------------------------------
echo "# Evolution Engine Report"
echo ""
echo "Date: ${today} | Lookback: ${DAYS} days"
echo ""

$MODE_REFLECT && do_reflect
$MODE_AUDIT && do_audit
$MODE_METRICS && do_metrics

echo "---"
echo "Evolution cycle complete."
