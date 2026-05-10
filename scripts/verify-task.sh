#!/usr/bin/env bash
# verify-task.sh — Post-task verification checklist.
#
# Usage: verify-task.sh <type> [path]
#
# Types: ios, script, infra, deploy, generic
#
# Exit 0 if all checks pass, exit 1 if any failures.

set -euo pipefail

# --- Colors ------------------------------------------------------------------
if [[ -t 1 ]]; then
  RED='\033[0;31m'; YELLOW='\033[0;33m'; GREEN='\033[0;32m'
  CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'
else
  RED=''; YELLOW=''; GREEN=''; CYAN=''; BOLD=''; RESET=''
fi

# --- Argument parsing --------------------------------------------------------
TASK_TYPE="${1:-}"
TARGET_PATH="${2:-.}"

if [[ -z "$TASK_TYPE" || "$TASK_TYPE" == "--help" || "$TASK_TYPE" == "-h" ]]; then
  echo "Usage: $(basename "$0") <type> [path]"
  echo ""
  echo "Post-task verification checklist."
  echo ""
  echo "Types:"
  echo "  ios      Check Xcode project, build artifacts, app icon, signing"
  echo "  script   Syntax check (bash -n), executability, shebangs"
  echo "  infra    Running services, LaunchAgents health"
  echo "  deploy   Git status, clean working tree"
  echo "  generic  Basic file existence checks"
  echo ""
  echo "Exit 0 if all pass, exit 1 if any failures."
  exit 0
fi

# --- State -------------------------------------------------------------------
passes=0
warnings=0
failures=0

pass() {
  (( passes++ )) || true
  printf "  ${GREEN}PASS${RESET}  %s\n" "$1"
}

warn() {
  (( warnings++ )) || true
  printf "  ${YELLOW}WARN${RESET}  %s\n" "$1"
}

fail() {
  (( failures++ )) || true
  printf "  ${RED}FAIL${RESET}  %s\n" "$1"
}

# --- iOS verification --------------------------------------------------------
verify_ios() {
  local dir="$1"
  echo -e "${BOLD}iOS Verification: ${dir}${RESET}"
  echo ""

  # Check for Xcode project
  if find "$dir" -maxdepth 2 \( -name '*.xcodeproj' -o -name '*.xcworkspace' \) -print -quit 2>/dev/null | grep -q .; then
    pass "Xcode project/workspace found"
  else
    fail "No .xcodeproj or .xcworkspace found"
  fi

  # Check for Swift source files
  local swift_count
  swift_count=$(find "$dir" -name '*.swift' -type f 2>/dev/null | wc -l | tr -d ' ')
  if (( swift_count > 0 )); then
    pass "Swift source files found (${swift_count})"
  else
    fail "No Swift source files found"
  fi

  # Check for app icon
  if find "$dir" -path '*/Assets.xcassets/AppIcon*' -print -quit 2>/dev/null | grep -q .; then
    pass "App icon asset found"
  else
    warn "No AppIcon asset found in Assets.xcassets"
  fi

  # Check for Info.plist or project config
  if find "$dir" -name 'Info.plist' -print -quit 2>/dev/null | grep -q . || \
     find "$dir" -name 'project.yml' -print -quit 2>/dev/null | grep -q .; then
    pass "Info.plist or project.yml found"
  else
    warn "No Info.plist or project.yml found"
  fi

  # Check for build artifacts (DerivedData is usually outside the project)
  if find "$dir" -name '*.app' -print -quit 2>/dev/null | grep -q .; then
    pass "Build artifact (.app) found"
  else
    warn "No .app build artifact found (may need to build first)"
  fi

  # Check signing identity
  if command -v security &>/dev/null; then
    local identities
    identities=$(security find-identity -v -p codesigning 2>/dev/null | grep -c 'valid identit' || echo 0)
    if (( identities > 0 )); then
      pass "Signing identity available (${identities} found)"
    else
      warn "No codesigning identities found"
    fi
  else
    warn "security command not available — cannot check signing"
  fi

  # Check for tests
  if find "$dir" -name '*Tests.swift' -o -name '*Test.swift' -print -quit 2>/dev/null | grep -q .; then
    pass "Test files found"
  else
    warn "No test files found"
  fi
}

# --- Script verification -----------------------------------------------------
verify_script() {
  local dir="$1"
  echo -e "${BOLD}Script Verification: ${dir}${RESET}"
  echo ""

  local script_files=()
  while IFS= read -r f; do
    script_files+=("$f")
  done < <(find "$dir" -name '*.sh' -type f 2>/dev/null)

  if (( ${#script_files[@]} == 0 )); then
    fail "No .sh files found in ${dir}"
    return
  fi

  pass "Found ${#script_files[@]} script(s)"

  for script in "${script_files[@]}"; do
    local name
    name=$(basename "$script")

    # Shebang check
    local first_line
    first_line=$(head -1 "$script")
    if [[ "$first_line" == "#!/usr/bin/env bash" || "$first_line" == "#!/bin/bash" ]]; then
      pass "${name}: valid shebang"
    else
      fail "${name}: missing or invalid shebang (got: ${first_line})"
    fi

    # Syntax check
    if bash -n "$script" 2>/dev/null; then
      pass "${name}: syntax OK"
    else
      fail "${name}: syntax error"
      bash -n "$script" 2>&1 | head -5 | while IFS= read -r line; do
        echo "        ${line}"
      done
    fi

    # Executability
    if [[ -x "$script" ]]; then
      pass "${name}: executable"
    else
      warn "${name}: not executable (chmod +x needed)"
    fi

    # Check for hardcoded paths
    if grep -qE '/Users/[a-zA-Z]' "$script" 2>/dev/null; then
      fail "${name}: contains hardcoded user paths"
    fi

    # Check for hardcoded emails
    if grep -qE '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}' "$script" 2>/dev/null; then
      fail "${name}: contains hardcoded email addresses"
    fi
  done
}

# --- Infra verification ------------------------------------------------------
verify_infra() {
  local dir="$1"
  echo -e "${BOLD}Infrastructure Verification${RESET}"
  echo ""

  # Check common services
  local services=("openclaw" "tailscaled" "caffeinate")
  for svc in "${services[@]}"; do
    if pgrep -x "$svc" &>/dev/null || pgrep -f "$svc" &>/dev/null; then
      pass "Service running: ${svc}"
    else
      warn "Service not found: ${svc}"
    fi
  done

  # Check LaunchAgents
  local launch_dir="${HOME}/Library/LaunchAgents"
  if [[ -d "$launch_dir" ]]; then
    local agent_count
    agent_count=$(find "$launch_dir" -name '*.plist' -type f 2>/dev/null | wc -l | tr -d ' ')
    pass "LaunchAgents directory exists (${agent_count} plists)"

    # Check for loaded agents
    while IFS= read -r plist; do
      local label
      label=$(basename "$plist" .plist)
      if launchctl list 2>/dev/null | grep -q "$label"; then
        pass "LaunchAgent loaded: ${label}"
      else
        warn "LaunchAgent not loaded: ${label}"
      fi
    done < <(find "$launch_dir" -name '*.plist' -type f 2>/dev/null)
  else
    warn "No LaunchAgents directory found"
  fi

  # Disk space
  local disk_avail
  disk_avail=$(df -h / 2>/dev/null | awk 'NR==2 {print $4}')
  if [[ -n "$disk_avail" ]]; then
    pass "Disk available: ${disk_avail}"
  fi

  # Memory
  if command -v vm_stat &>/dev/null; then
    pass "System memory accessible via vm_stat"
  fi
}

# --- Deploy verification -----------------------------------------------------
verify_deploy() {
  local dir="$1"
  echo -e "${BOLD}Deploy Verification: ${dir}${RESET}"
  echo ""

  if [[ ! -d "${dir}/.git" ]]; then
    fail "Not a git repository"
    return
  fi

  pass "Git repository found"

  # Check for uncommitted changes
  local changes
  changes=$(cd "$dir" && git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
  if (( changes == 0 )); then
    pass "Working tree clean"
  else
    warn "Uncommitted changes: ${changes} file(s)"
    cd "$dir" && git status --porcelain 2>/dev/null | head -5 | while IFS= read -r line; do
      echo "        ${line}"
    done
  fi

  # Check current branch
  local branch
  branch=$(cd "$dir" && git branch --show-current 2>/dev/null)
  if [[ -n "$branch" ]]; then
    pass "On branch: ${branch}"
  else
    warn "Detached HEAD state"
  fi

  # Check if ahead/behind remote
  local ahead behind
  ahead=$(cd "$dir" && git rev-list --count @{upstream}..HEAD 2>/dev/null || echo "?")
  behind=$(cd "$dir" && git rev-list --count HEAD..@{upstream} 2>/dev/null || echo "?")
  if [[ "$ahead" != "?" ]]; then
    if (( ahead == 0 && behind == 0 )); then
      pass "Up to date with remote"
    else
      warn "Ahead: ${ahead}, Behind: ${behind}"
    fi
  fi

  # Check for tags
  local latest_tag
  latest_tag=$(cd "$dir" && git describe --tags --abbrev=0 2>/dev/null || echo "none")
  pass "Latest tag: ${latest_tag}"
}

# --- Generic verification ----------------------------------------------------
verify_generic() {
  local dir="$1"
  echo -e "${BOLD}Generic Verification: ${dir}${RESET}"
  echo ""

  if [[ -d "$dir" ]]; then
    pass "Directory exists"
  else
    fail "Directory not found: ${dir}"
    return
  fi

  # Count files
  local file_count
  file_count=$(find "$dir" -type f 2>/dev/null | wc -l | tr -d ' ')
  pass "Contains ${file_count} file(s)"

  # Check for README
  if [[ -f "${dir}/README.md" || -f "${dir}/readme.md" ]]; then
    pass "README.md found"
  else
    warn "No README.md"
  fi

  # Check for common config files
  for cfg in .gitignore .editorconfig LICENSE; do
    if [[ -f "${dir}/${cfg}" ]]; then
      pass "${cfg} found"
    fi
  done

  # Disk usage
  local dir_size
  dir_size=$(du -sh "$dir" 2>/dev/null | cut -f1)
  pass "Total size: ${dir_size}"
}

# --- Dispatch ----------------------------------------------------------------
echo ""
case "$TASK_TYPE" in
  ios)     verify_ios "$TARGET_PATH" ;;
  script)  verify_script "$TARGET_PATH" ;;
  infra)   verify_infra "$TARGET_PATH" ;;
  deploy)  verify_deploy "$TARGET_PATH" ;;
  generic) verify_generic "$TARGET_PATH" ;;
  *)
    echo "Unknown task type: ${TASK_TYPE}"
    echo "Valid types: ios, script, infra, deploy, generic"
    exit 1
    ;;
esac

# --- Summary -----------------------------------------------------------------
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
printf "Results: ${GREEN}%d PASS${RESET} | ${YELLOW}%d WARN${RESET} | ${RED}%d FAIL${RESET}\n" "$passes" "$warnings" "$failures"

if (( failures > 0 )); then
  echo -e "${RED}Verification FAILED — ${failures} issue(s) need attention.${RESET}"
  exit 1
else
  if (( warnings > 0 )); then
    echo -e "${YELLOW}Verification PASSED with ${warnings} warning(s).${RESET}"
  else
    echo -e "${GREEN}Verification PASSED — all checks clean.${RESET}"
  fi
  exit 0
fi
