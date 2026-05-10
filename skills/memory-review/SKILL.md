---
name: memory-review
description: Memory consolidation and review. Clean up, organize, and audit all memory layers.
---

# Memory Review

Structured process for reviewing, consolidating, and cleaning up all memory layers. Memory is your continuity — keep it accurate, organized, and useful.

## When to Use
- Scheduled memory review (every 3-7 days)
- Memory feels cluttered or contradictory
- After major project milestones
- During dream/consolidation cycles
- When daily logs are piling up unsummarized
- After receiving "you should have remembered X" feedback

## Workflow

### Step 1: Gather All Memory Layers

Read everything before changing anything.

```bash
# Long-term memory
cat MEMORY.md

# Environment and tools
cat TOOLS.md

# Behavioral rules
cat AGENTS.md

# Recent daily logs (last 7-14 days)
ls -la memory/
for f in memory/2026-05-*.md; do echo "=== $f ==="; cat "$f"; done

# Heartbeat state
cat memory/heartbeat-state.json 2>/dev/null

# Any other state files
ls memory/*.json memory/*.yaml 2>/dev/null
```

### Step 2: Classify Entries by Destination

Each piece of information belongs in exactly one place:

| Destination | What Goes There | Examples |
|------------|----------------|---------|
| **MEMORY.md** | Long-term facts about user, projects, preferences, decisions | "User prefers X", "Project Y uses architecture Z" |
| **AGENTS.md** | Behavioral rules, gates, workflow patterns | "Always verify before done", "Don't burst messages" |
| **TOOLS.md** | Environment details, CLI notes, service configs | "API key is X", "Service runs on port Y" |
| **Daily logs** | Ephemeral task records, session notes | "Fixed bug in file X", "Deployed version Y" |
| **Delete** | Obsolete, duplicate, or derivable information | Completed tasks, outdated configs, things `ls` can tell you |

### Step 3: Find Issues

Scan for these specific problems:

**Duplicates** — Same fact recorded in multiple places.
- Example: API key in both MEMORY.md and TOOLS.md
- Fix: Keep in the canonical location, remove from others

**Contradictions** — Two entries that disagree.
- Example: MEMORY.md says "user prefers email" but daily log says "user switched to Slack"
- Fix: Verify which is current, update the stale one

**Stale entries** — Information that's no longer accurate.
- Example: "Service X is down" when it was fixed 5 days ago
- Fix: Verify current state, update or remove

**Orphaned entries** — References to things that no longer exist.
- Example: "See project plan in /docs/plan.md" but file was deleted
- Fix: Remove the reference or note it's gone

**Misplaced entries** — Correct info in the wrong file.
- Example: Behavioral rule in MEMORY.md instead of AGENTS.md
- Fix: Move to canonical location

**Missing entries** — Important context not recorded anywhere.
- Example: Major decision made 3 days ago, not in MEMORY.md
- Fix: Add from daily logs or session context

### Step 4: Present Report

Compile findings into a structured report before making changes:

```markdown
## Memory Review Report — [DATE]

### Promotions (daily → MEMORY.md)
1. [Entry]: [from daily log DATE] → MEMORY.md
   - Reason: Long-term relevant, not derivable

### Demotions (MEMORY.md → daily/delete)
1. [Entry]: Remove from MEMORY.md
   - Reason: Completed / obsolete / derivable via `git log`

### Cleanup
1. [Duplicate]: In MEMORY.md and TOOLS.md → keep in TOOLS.md
2. [Stale]: "[old fact]" → update to "[current fact]"
3. [Contradiction]: MEMORY.md says X, daily says Y → verify and resolve

### Relocations
1. [Entry]: MEMORY.md → AGENTS.md (it's a behavioral rule)
2. [Entry]: MEMORY.md → TOOLS.md (it's an environment detail)

### Ambiguous (Need Confirmation)
1. [Entry]: Not sure if still accurate — needs verification
   - How to verify: [check command or question to ask]

### No Action
- [Entries reviewed and confirmed accurate/well-placed]

### Summary
- Entries reviewed: X
- Promotions: X
- Demotions: X
- Cleanups: X
- Relocations: X
- Ambiguous: X
```

### Step 5: Apply Changes

Apply in this order to minimize risk:

1. **Remove duplicates first** — No information lost, just deduplication
2. **Move misplaced entries** — Relocate to canonical homes
3. **Promote important entries** — Daily → MEMORY.md
4. **Update stale entries** — Verify current state, then update
5. **Remove obsolete entries** — Only after confirming they're truly obsolete
6. **Archive old daily logs** — Summarize 14+ day old logs, then archive or delete

After each batch of changes, verify the target file reads correctly.

## Rules

1. **Read everything first.** Don't modify until you've seen the full picture across all layers.
2. **Present before modifying.** The report in Step 4 is mandatory — never silently reorganize memory.
3. **Ask about ambiguous cases.** If you can't verify whether something is stale, flag it rather than deleting.
4. **Preserve detail.** When consolidating daily logs into MEMORY.md, keep the useful specifics. "Fixed auth bug in UserService.swift by adding nil check on line 47" is better than "Fixed a bug."
5. **Verify stale memories.** Before marking something obsolete, check: run the command, read the file, confirm the state. Don't assume.
6. **Don't save derivable info.** If `ls`, `grep`, `git log`, or a quick command can tell you, don't store it in memory. Store the non-obvious.
7. **One canonical location.** Every fact lives in exactly one file. Cross-references are fine ("see TOOLS.md for API keys") but don't duplicate the actual data.
8. **Date your changes.** When updating MEMORY.md entries, note when the update happened so future reviews know how fresh the data is.
