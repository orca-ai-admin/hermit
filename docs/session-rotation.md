# Session Rotation

Why long sessions degrade AI agent quality, how to detect it, and how to rotate sessions without losing context.

## The Problem

Long sessions degrade rule compliance. This is proven, not theoretical.

AI agents load their behavioral rules (personality, formatting requirements, safety gates) at the beginning of a session. As the session grows with task content — tool call results, code, logs, back-and-forth — those initial rules lose weight in the context window. The model doesn't "forget" them in a human sense, but they become proportionally less influential as the context fills with other content.

**What degrades:**
- After ~30 assistant messages or ~250KB of session content, structural rules begin to fade
- Behavioral gates (burst prevention, banned phrases, verification requirements) are the first to go
- The agent that followed every rule perfectly for 20 messages will start breaking them at 50+
- By 100+ messages, the agent operates primarily on recent context, not session-start instructions

**What this causes:**
- Message burst violations on messaging platforms
- Banned phrase leaks ("Want me to...?" when the rule says never ask permission)
- Sloppy verification (claiming "done" without actually checking)
- Personality drift (becoming generic instead of maintaining configured persona)

## Evidence

Context dilution is observable and reproducible:

- **Banned phrase residuals** occurred exclusively in sessions with 375+ messages. Shorter sessions with identical rules had zero violations. The only variable was session length.

- **A 9-message burst** occurred in a 1776KB session despite the anti-burst rule being loaded at session start. The same agent, 40 minutes later in the same session, produced perfect single-message responses — demonstrating that the rules weren't gone, just intermittently drowned out.

- **Rule compliance tracking** across sessions shows a clear correlation: sessions under 30 messages maintain >98% compliance with behavioral rules. Sessions over 60 messages drop below 80%. Sessions over 100 messages are essentially ungoverned.

The mechanism is straightforward: if your behavioral rules are 5KB and your session is 50KB, those rules are 10% of context. At 500KB, they're 1%. The model's attention is finite, and task content competes with rules for it.

## Thresholds

### ✅ Under 30 Messages — Proceed Normally

No intervention needed. Rule compliance is high. Context window has plenty of room for both rules and task content.

### ⚠️ 30-60 Messages — Finish and Rotate

The session is getting long. Behavioral rules are starting to fade. The right move:

1. Finish the current task
2. Suggest rotation before taking on new complex work
3. Preserve context (see below) so the next session picks up cleanly

Don't panic — the session isn't broken. But starting a new multi-step task in this range risks degraded quality.

### 🔴 Over 60 Messages — Stop and Rotate

Do not start new complex tasks. Context dilution is actively degrading rule compliance. The agent should:

1. Proactively tell the user: "This session is getting long — let's start fresh so I'm sharp."
2. Preserve context before rotating
3. Any new complex work goes in the fresh session

This isn't about the agent "getting tired" — it's about the mathematical reality of fixed context windows and proportional attention.

## Making Rotation Friction-Free

The #1 resistance to rotation is fear of losing context. "But we've discussed so much in this session — starting fresh means re-explaining everything." This is solvable.

### Context Preservation

Before suggesting rotation, run a context summarizer that extracts key information from the current session:

```bash
#!/bin/bash
# session-context-summarizer.sh
# Extracts key context from oversized sessions before rotation

SESSION_FILE="$1"  # Path to current session log
OUTPUT_DIR="memory/session-summaries"

mkdir -p "$OUTPUT_DIR"

# Extract:
# 1. Active tasks and their current status
# 2. Decisions made during the session
# 3. File paths and line numbers referenced
# 4. Unresolved questions or blockers
# 5. Key findings from research/investigation

SUMMARY_FILE="$OUTPUT_DIR/$(date +%Y-%m-%d-%H%M).md"

# ... extraction logic ...

echo "Context saved to $SUMMARY_FILE"
```

**What to preserve:**
- Active tasks and their status (in-progress, blocked, done)
- Decisions made ("we decided to use Redis instead of Memcached because...")
- Important file paths and what was found in them
- Unresolved questions or blockers
- Any context the next session would need to continue the work

**What NOT to preserve:**
- Full tool call outputs (too large, next session can re-read files)
- Debugging dead ends (if it didn't work, the next session doesn't need the details)
- Conversational filler

### The Rotation Message

Include context preservation status in the rotation suggestion:

```
"This session is getting long — context dilution affects quality after this many messages.
All recent context is saved to memory — a fresh session picks up where we left off.
Let's start fresh with /new."
```

This reassures the user that rotation isn't losing anything. The preserved context gets loaded as part of the memory system in the new session.

## Detection

### Session Size Monitor

A monitoring script checks session sizes during periodic health checks:

```bash
#!/bin/bash
# session-context-monitor.sh
# Checks active session sizes and flags oversized ones

# Thresholds (bytes)
WARNING_SIZE=256000     # ~250KB
CRITICAL_SIZE=512000    # ~500KB
EMERGENCY_SIZE=1048576  # ~1MB

# Check active session files
for session in /path/to/sessions/active/*.json; do
    size=$(wc -c < "$session")
    name=$(basename "$session" .json)

    if [ "$size" -gt "$EMERGENCY_SIZE" ]; then
        echo "EMERGENCY: Session $name is $(( size / 1024 ))KB — rotate immediately"
    elif [ "$size" -gt "$CRITICAL_SIZE" ]; then
        echo "CRITICAL: Session $name is $(( size / 1024 ))KB — suggest rotation"
    elif [ "$size" -gt "$WARNING_SIZE" ]; then
        echo "WARNING: Session $name is $(( size / 1024 ))KB — nearing rotation threshold"
    fi
done
```

**Integration:**
- Run during heartbeat checks (2-4x daily)
- On WARNING: note internally, be prepared to suggest rotation
- On CRITICAL: next interaction with the user must include a rotation suggestion
- On EMERGENCY: refuse new complex work, actively push for rotation

### Message Count Tracking

If session files don't expose size directly, count assistant messages as a proxy:

```bash
# Count assistant turns in a session
assistant_messages=$(grep -c '"role":"assistant"' "$session_file")

if [ "$assistant_messages" -gt 60 ]; then
    echo "CRITICAL: $assistant_messages assistant messages — rotate"
elif [ "$assistant_messages" -gt 30 ]; then
    echo "WARNING: $assistant_messages assistant messages — consider rotation"
fi
```

## Why Not Just Use Longer Context Windows?

Longer context windows delay the problem but don't solve it. The issue isn't running out of context — it's proportional attention. Rules at position 0 in a 200K-token context compete with 200K tokens of task content for the model's attention. Making the window 500K tokens just means the rules compete with even more content.

The real fix is rotation: keep sessions short so rules remain a meaningful proportion of context. This is a fundamental property of how transformer attention works, not a temporary limitation.

## Summary

| Session State | Action | Risk |
|---|---|---|
| < 30 messages | Continue normally | Low |
| 30-60 messages | Finish task, then rotate | Medium — rules fading |
| > 60 messages | Stop new work, rotate now | High — rules unreliable |
| > 250KB | Emergency rotation | Critical — compliance <80% |

The cost of rotation is near-zero when context is preserved. The cost of not rotating is degraded quality, rule violations, and user frustration. Always rotate.
