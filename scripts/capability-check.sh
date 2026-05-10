#!/usr/bin/env bash
# capability-check.sh — Inventory available capabilities before claiming "can't"
# Part of the Hermit framework's CHECK BEFORE CAN'T red gate.
#
# Usage: ./scripts/capability-check.sh [tool-name]
#   No args: full inventory
#   With arg: check if specific tool exists
#
# Run this BEFORE any response containing "I can't", "I don't have access",
# or "not available". The default assumption is: "I probably CAN."

set -euo pipefail

echo "🔍 Capability Check — $(date '+%Y-%m-%d %H:%M:%S')"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# If checking a specific tool
if [[ $# -gt 0 ]]; then
  tool="$1"
  echo ""
  echo "Checking for: $tool"
  echo ""
  
  # Check PATH
  if command -v "$tool" &>/dev/null; then
    location=$(command -v "$tool")
    echo "  ✅ Found: $location"
    echo ""
    echo "  Version/help info:"
    "$tool" --version 2>&1 | head -3 || "$tool" -v 2>&1 | head -3 || echo "  (no version flag)"
    exit 0
  fi
  
  # Check common locations
  for dir in /usr/local/bin /opt/homebrew/bin "$HOME/.local/bin" "$HOME/bin"; do
    if [[ -x "$dir/$tool" ]]; then
      echo "  ✅ Found (not in PATH): $dir/$tool"
      exit 0
    fi
  done
  
  # Check if it's a function or alias
  if type "$tool" &>/dev/null; then
    echo "  ✅ Found as: $(type "$tool")"
    exit 0
  fi
  
  echo "  ❌ Not found: $tool"
  echo "  Checked: PATH, /usr/local/bin, /opt/homebrew/bin, ~/.local/bin, ~/bin"
  exit 1
fi

# Full inventory mode
echo ""
echo "📋 System Info:"
echo "  OS: $(uname -s) $(uname -r) ($(uname -m))"
echo "  Shell: $SHELL"
echo "  User: $(whoami)"
echo ""

echo "🔧 Available CLIs:"
# Common useful tools — add your own
TOOLS_TO_CHECK=(
  git gh curl wget jq python3 node npm
  docker kubectl terraform
  ffmpeg imagemagick
  sqlite3 psql mysql redis-cli
  aws gcloud az
  brew apt yum
  screen tmux
  ssh scp rsync
  zip unzip tar
  crontab at
)

for tool in "${TOOLS_TO_CHECK[@]}"; do
  if command -v "$tool" &>/dev/null; then
    echo "  ✅ $tool — $(command -v "$tool")"
  fi
done

echo ""
echo "📁 Workspace Scripts:"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -d "$SCRIPT_DIR" ]]; then
  for script in "$SCRIPT_DIR"/*.sh; do
    if [[ -f "$script" ]]; then
      echo "  📜 $(basename "$script")"
    fi
  done
fi

echo ""
echo "📄 Key Files:"
WORKSPACE_ROOT="$(dirname "$SCRIPT_DIR")"
for file in TOOLS.md SOUL.md AGENTS.md MEMORY.md IDENTITY.md; do
  if [[ -f "$WORKSPACE_ROOT/$file" ]]; then
    echo "  📝 $file"
  fi
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "💡 Before saying 'I can't':"
echo "   1. Check TOOLS.md for documented capabilities"
echo "   2. Try: which <tool> or <tool> --help"
echo "   3. Check /usr/local/bin and /opt/homebrew/bin"
echo "   4. Only claim inability after ALL checks fail"
echo ""
echo "Default assumption: I probably CAN."
