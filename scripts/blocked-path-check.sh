#!/usr/bin/env bash
# blocked-path-check.sh — Lateral thinking enforcement
# Part of the Hermit framework's BLOCKED PATH red gate.
#
# Usage: ./scripts/blocked-path-check.sh [goal-description]
#
# Run this when an approach fails. It forces you to think laterally
# before reporting "impossible" or "blocked" to the human.
#
# This script is a checklist/prompt — it doesn't check running services.
# It's designed to be read by the agent as a forcing function for creative thinking.

set -euo pipefail

GOAL="${1:-<not specified>}"

cat << 'EOF'
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚧 BLOCKED PATH CHECKLIST
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

One path is blocked. That's ONE path — not proof the goal is impossible.

Before reporting "blocked" or "impossible" to the human:

┌─────────────────────────────────────────────────┐
│ STEP 1: REFRAME THE GOAL                        │
│                                                  │
│ What does the human actually want?               │
│ (Not "use this specific API" — the OUTCOME)      │
│                                                  │
│ Write it as: "The human wants to ___________"    │
└─────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────┐
│ STEP 2: ENUMERATE ALTERNATIVES (minimum 3)      │
│                                                  │
│ Common lateral moves:                            │
│                                                  │
│ • API can't do X → Web portal? CLI? AppleScript?│
│ • Resource doesn't exist → Repurpose existing?   │
│   Create via different path?                     │
│ • Service blocked → Different service? Cached    │
│   version? Local alternative?                    │
│ • Permission denied → Different account? Elevate?│
│   Ask human to grant access?                     │
│ • Tool broken → Different tool? Manual process?  │
│   Build a workaround?                            │
│ • "Not supported" → Older version? Different     │
│   format? Shim/wrapper?                          │
│                                                  │
│ List your 3 alternatives:                        │
│ 1. _____________                                 │
│ 2. _____________                                 │
│ 3. _____________                                 │
└─────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────┐
│ STEP 3: ATTEMPT (at least 1)                    │
│                                                  │
│ Try the most promising alternative BEFORE        │
│ reporting to the human. If it fails too, try     │
│ the next one.                                    │
└─────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────┐
│ STEP 4: REPORT WITH ATTEMPTS                    │
│                                                  │
│ Only report "blocked" after 3+ approaches fail.  │
│ Include what you tried and why each failed.      │
│                                                  │
│ ❌ "The API doesn't support this."              │
│ ✅ "Tried 3 approaches: API returned 403, CLI   │
│     requires admin role, web portal needs 2FA.   │
│     Recommend: grant admin role or do it         │
│     manually via portal."                        │
└─────────────────────────────────────────────────┘

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Remember: The human's patience for "it can't be done" is low.
Their patience for "I tried X, Y, and Z — here's what I recommend" is high.

EOF

echo "Goal: $GOAL"
echo ""
echo "Now enumerate your alternatives and try at least one."
