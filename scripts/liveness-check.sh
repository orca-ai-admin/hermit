#!/usr/bin/env bash
# liveness-check.sh — Verify infrastructure is actually running
# Part of the Hermit framework's LIVENESS red gate.
#
# Usage: ./scripts/liveness-check.sh
#
# Exit codes:
#   0 = all checks passed
#   1 = one or more checks failed
#
# Customize the SERVICES array below for your infrastructure.

set -euo pipefail

# ═══════════════════════════════════════════════
# CONFIGURATION — Edit these for your setup
# ═══════════════════════════════════════════════

# Services to check: "name|check_command"
# The check_command should exit 0 if healthy, non-zero if not.
SERVICES=(
  "example-web|curl -sf http://localhost:8080/health > /dev/null 2>&1"
  "example-db|pg_isready -q 2>/dev/null"
  # Add your services here:
  # "service-name|command-to-check-health"
)

# Optional: disk space threshold (percentage)
DISK_THRESHOLD=90

# Optional: check these URLs are reachable
URLS=(
  # "https://your-app.example.com"
)

# ═══════════════════════════════════════════════
# CHECKS
# ═══════════════════════════════════════════════

FAILED=0
PASSED=0
WARNINGS=0

echo "🔍 Liveness Check — $(date '+%Y-%m-%d %H:%M:%S')"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check services
for service_entry in "${SERVICES[@]}"; do
  IFS='|' read -r name cmd <<< "$service_entry"
  if eval "$cmd" 2>/dev/null; then
    echo "  ✅ $name"
    ((PASSED++))
  else
    echo "  ❌ $name — FAILED"
    ((FAILED++))
  fi
done

# Check disk space
echo ""
echo "📦 Disk Space:"
while IFS= read -r line; do
  usage=$(echo "$line" | awk '{print $5}' | tr -d '%')
  mount=$(echo "$line" | awk '{print $6}')
  if [[ -n "$usage" ]] && [[ "$usage" -gt "$DISK_THRESHOLD" ]]; then
    echo "  ⚠️  $mount at ${usage}% (threshold: ${DISK_THRESHOLD}%)"
    ((WARNINGS++))
  fi
done < <(df -h 2>/dev/null | grep -E '^/' || true)

if [[ "$WARNINGS" -eq 0 ]]; then
  echo "  ✅ All volumes within threshold"
fi

# Check URLs
if [[ ${#URLS[@]} -gt 0 ]]; then
  echo ""
  echo "🌐 URL Checks:"
  for url in "${URLS[@]}"; do
    status=$(curl -sf -o /dev/null -w "%{http_code}" "$url" 2>/dev/null || echo "000")
    if [[ "$status" =~ ^2 ]]; then
      echo "  ✅ $url ($status)"
      ((PASSED++))
    else
      echo "  ❌ $url (HTTP $status)"
      ((FAILED++))
    fi
  done
fi

# Summary
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [[ "$FAILED" -gt 0 ]]; then
  echo "❌ LIVENESS CHECK FAILED — $FAILED issue(s) detected"
  echo "   Do NOT report this change as 'done' until all issues are resolved."
  exit 1
elif [[ "$WARNINGS" -gt 0 ]]; then
  echo "⚠️  LIVENESS CHECK PASSED with $WARNINGS warning(s)"
  exit 0
else
  echo "✅ LIVENESS CHECK PASSED — all $PASSED checks healthy"
  exit 0
fi
