# Memory System

Hermit's memory system is designed around a simple insight: LLMs forget everything between sessions, but the files they read don't.

The system uses a three-tier hierarchy inspired by how human memory actually works.

---

## The Three Tiers

### Tier 1: Working Memory (Session Context)

This is the active conversation — the context window. It's powerful but finite.

- **Duration:** One session
- **Size:** Limited by model context window (typically 128K-200K tokens)
- **Content:** Current conversation, loaded files, tool results
- **Limitation:** Gone when the session ends

### Tier 2: Daily Notes (Short-Term Memory)

Raw logs of what happened each day. Cheap to write, messy by design.

- **Location:** `memory/YYYY-MM-DD.md`
- **Duration:** Days to weeks before consolidation
- **Content:** Decisions, events, corrections, discoveries, todos
- **Written by:** The agent during normal operation
- **Read at:** Session start (today + yesterday)

**Example daily note:**

```markdown
# 2026-03-15

## Events
- Deployed v2.3.1 to production at 14:30
- Human mentioned they'll be traveling Mar 18-22
- CI pipeline failed on `feature/auth` — fixed missing env var

## Corrections
- Sent 4 messages in a row to Discord → human flagged burst violation
- Need to consolidate tool call results before responding

## Decisions
- Switching from REST to GraphQL for the new API endpoints
- Will run dream cycle tomorrow — 5 days of notes accumulated

## Todo
- [ ] Set up monitoring alerts for the new deployment
- [ ] Update TOOLS.md with new CLI that was installed
```

### Tier 3: Long-Term Memory (MEMORY.md)

Curated essence. Not logs — insights. Updated during dream cycles.

- **Location:** `MEMORY.md`
- **Duration:** Indefinite (persists until pruned)
- **Content:** User preferences, behavioral patterns, project context, reference pointers
- **Written by:** The agent during dream cycles
- **Read at:** Session start (main sessions only)

---

## Dream Cycles

Dream cycles are the bridge between short-term and long-term memory. Named after the neuroscience of sleep consolidation — during sleep, the brain replays experiences and transfers important patterns from hippocampus (short-term) to cortex (long-term).

### The Process

1. **Gather** — Read all daily notes from the past 3-7 days
2. **Extract** — Identify patterns, recurring themes, important decisions
3. **Consolidate** — Write curated insights to MEMORY.md
4. **Prune** — Remove outdated or contradicted information from MEMORY.md
5. **Archive** — Optionally mark daily notes as processed

### When to Dream

- Every 3-5 days (more frequent during active periods)
- After significant events or corrections
- During heartbeats when nothing urgent needs attention
- Before memory files get too large

### What to Consolidate

**Always consolidate:**
- User preferences and communication patterns
- Corrections (especially repeated ones — these become behavioral insights)
- Important project decisions and their rationale
- Discovered capabilities or limitations

**Never consolidate:**
- Raw event logs (leave those in daily notes)
- Temporary context that won't matter next week
- Information easily discoverable from files (`ls`, `git log`, etc.)
- Secrets or credentials

### Example Consolidation

**Daily notes (raw):**
```
2026-03-13: Human corrected me for sending 5 messages in a row
2026-03-14: Almost sent a burst again, caught it. Consolidated to 1 message.
2026-03-15: Human said "that's much better" about message format
```

**MEMORY.md (consolidated):**
```
## Feedback & Corrections
- Anti-burst: Human is very sensitive to message bursts. Consolidate ALL
  tool results before responding. Even 3 messages feels like too many.
  Pattern was corrected 2026-03-13, confirmed fixed 2026-03-15.
```

See [examples/dream-cycle.md](../examples/dream-cycle.md) for a full walkthrough.

---

## Memory Categories

MEMORY.md organizes memories into four categories:

### User Memories
What you've learned about your human — preferences, patterns, habits, important context.

### Feedback & Corrections
Patterns from corrections. What you've been told to do differently, and whether the fix stuck.

### Project Context
Non-derivable context about active projects. Things that `grep` can't tell you — intentions, decisions, status.

### Reference Pointers
Links to external systems, accounts, important paths. Quick-reference material.

---

## Memory Hygiene

### Do Write
- Decisions and their rationale
- Corrections and the behavioral change they triggered
- User preferences discovered through interaction
- Important dates and deadlines
- Context that would be lost without explicit recording

### Don't Write
- Things discoverable from the filesystem
- Raw command outputs
- Temporary debugging context
- Secrets, credentials, or tokens (use environment variables or secure storage)

### Do Prune
- Outdated project status (project shipped 3 weeks ago? remove the "in progress" note)
- Contradicted information (user changed their preference)
- Completed todos
- Context that's now in permanent documentation

---

## Security Considerations

- **MEMORY.md should only be read in the agent's main session** — not in shared/group contexts. It contains personal information about the human.
- Daily notes may contain sensitive operational details. The `.gitignore` template excludes the `memory/` directory.
- During dream cycles, avoid consolidating anything that shouldn't persist (temporary credentials, one-time codes, etc.).

---

## Framework Integration

The memory system is framework-agnostic. Any agent framework that supports:
1. Reading files at session start
2. Writing files during operation
3. Periodic execution (for dream cycles)

...can implement Hermit's memory system. The files are just markdown — no special format, no database, no API.
