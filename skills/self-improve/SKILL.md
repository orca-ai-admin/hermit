---
name: self-improve
description: Periodic self-improvement audit. Review corrections, identify patterns, propose changes to skills, memory, and behavior.
---

# Self-Improvement Audit

Structured process for learning from recent experience. Review what happened, find patterns, and propose concrete improvements.

## When to Use
- Periodic review (every 3-7 days)
- After receiving corrections or strong feedback
- During self-maintenance / dream cycles
- When noticing repeated mistakes
- After a particularly successful or failed task

## Workflow

### Step 1: Gather Recent Context

Collect the raw material for analysis:

```bash
# Last 5-7 daily logs
ls -la memory/
cat memory/$(date -v-1d +%Y-%m-%d).md  # yesterday
cat memory/$(date +%Y-%m-%d).md          # today
# ... back 5-7 days

# Long-term memory
cat MEMORY.md

# Recent corrections (if tracked)
cat ~/self-improving/corrections.md 2>/dev/null
cat ~/self-improving/memory.md 2>/dev/null
```

Look for: corrections, feedback, task outcomes, recurring themes.

### Step 2: Identify Feedback Patterns

Categorize feedback into:

| Category | What to Look For |
|----------|-----------------|
| **Corrections** | "Don't do X", "That was wrong", explicit fixes |
| **Confirmations** | "That worked", "Perfect", positive signals |
| **Repeated mistakes** | Same error type appearing 2+ times |
| **Near-misses** | Things that almost went wrong |
| **Capability gaps** | Tasks you couldn't complete or struggled with |

For each pattern, note:
- **Frequency**: How often did this occur?
- **Severity**: Minor annoyance or trust-breaking?
- **Root cause**: Why did it happen? (Not just what happened)
- **Existing mitigation**: Is there already a rule/gate for this?

### Step 3: Identify Skill Candidates

A repeatable process deserves a skill when:
- It involves 5+ steps that you've done 3+ times
- The steps are non-obvious (not just "run a command")
- Getting it wrong has consequences
- A checklist or template would prevent mistakes

**Don't create skills for:**
- One-off tasks (even complex ones)
- Simple command sequences documented elsewhere
- Tasks that change significantly each time

For each candidate, draft:
- Name and description
- Trigger conditions (when to activate)
- Step-by-step workflow
- Common pitfalls

### Step 4: Memory Consolidation Needs

Check if memory maintenance is due:

- **Dream cycle**: Has it been 3+ days since last consolidation?
- **Stale entries**: Any memory entries that reference completed/obsolete items?
- **Missing entries**: Recent important context not yet in long-term memory?
- **Conflicting entries**: Two memories that contradict each other?
- **Daily log cleanup**: Old daily logs that should be summarized and archived?

### Step 5: Propose Changes

Compile a structured report:

```markdown
## Self-Improvement Report — [DATE]

### Feedback Patterns
1. [Pattern]: [description, frequency, severity]
   - Root cause: [why]
   - Proposed fix: [specific change to AGENTS.md / SOUL.md / skill]

### Skill Proposals
1. [Skill name]: [what it does]
   - Trigger: [when to use]
   - Justification: [why it's worth creating]

### Memory Updates
1. [Promote/Demote/Update/Delete]: [entry]
   - Reason: [why]

### Documentation Updates
1. [File]: [what to change]
   - Reason: [why]

### No Action Needed
- [Things reviewed but fine as-is]
```

### Step 6: Apply Changes

**Present all proposals before making any changes.** Then:

1. Apply behavioral changes (AGENTS.md, SOUL.md) — these prevent future mistakes
2. Create/update skills — these encode repeatable processes
3. Update memory (MEMORY.md) — consolidate and clean
4. Update documentation (TOOLS.md, etc.) — keep references accurate
5. Log the audit itself in daily notes

## Rules

1. **Present before modifying.** Never silently change behavioral rules or memory.
2. **Include reasoning.** Every proposed change needs a "why" — link to specific incidents.
3. **Don't create skills for one-offs.** Three occurrences minimum before encoding as a skill.
4. **Preserve nuance.** When consolidating, keep the detail that matters. "Config change needs restart" is better than "remember to restart."
5. **Track what works too.** Successes are data. A confirmation that a pattern works reinforces it.
6. **Be honest about root causes.** "I forgot" is not a root cause. "Rule was in AGENTS.md line 200 and context window was 400KB" is.
7. **Small, frequent audits > large, rare ones.** A 10-minute review every 3 days beats a 2-hour review monthly.
