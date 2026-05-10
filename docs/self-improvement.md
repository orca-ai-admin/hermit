# Self-Improvement Engine

The most unusual thing about Hermit: the agent debugs its own behavior.

Not metaphorically. The agent literally mines corrections from its interaction history, forms hypotheses about why behavioral patterns occur, designs experiments to fix them, and measures the results.

---

## The Cycle

```
Corrections Mining → Hypothesis → Experiment → Measurement → Evolution
       ↑                                                        |
       └────────────────────────────────────────────────────────┘
```

### 1. Corrections Mining

The agent maintains a corrections log — every time the human corrects a behavior, it's recorded with:
- **Date** of the correction
- **What happened** (the behavior)
- **What was expected** (the correct behavior)
- **Frequency** (how many times this has happened)
- **Root cause hypothesis** (why the agent thinks it happens)

Example:
```markdown
## Correction: Message Bursts
- Dates: 2026-03-11, 2026-03-12, 2026-03-13
- Behavior: Sending 5+ separate messages when answering a question
- Expected: Single consolidated response after all tool calls
- Frequency: 3 incidents in 3 days
- Root cause: Agent narrates each tool call, and each narration becomes a separate message on chat surfaces
```

### 2. Hypothesis

Once a pattern emerges (3+ corrections of the same type), the agent forms a hypothesis:

> "Message bursts occur because I instinctively narrate my process ('Let me check...', 'Now looking at...'). Each narration between tool calls becomes a separate message on chat surfaces. The behavior persists because the instruction in my system prompt gets diluted in long sessions."

### 3. Experiment Design

Experiments follow a structured format:

```markdown
## Experiment: Anti-Burst Structural Enforcement
- ID: exp-001
- Hypothesis: Adding a Red Gate to SOUL.md with a monitoring script will reduce bursts
- Metric: Burst count per 72-hour window
- Baseline: ~4-5 bursts/week
- Target: < 1 burst/week
- Method:
  1. Add ANTI-BURST gate to SOUL.md with explicit rules
  2. Create burst-guard.sh to detect and count bursts
  3. Run burst-guard.sh during heartbeats
- Duration: 7 days
- Rollback: Remove the gate if burst count increases (shouldn't happen)
```

### 4. Measurement

After the experiment period:
- Run the measurement scripts
- Compare against baseline
- Document any side effects

```markdown
## Experiment Results: exp-001
- Duration: 7 days (2026-03-14 to 2026-03-21)
- Baseline: 4-5 bursts/week
- Result: 0 bursts in 7 days
- Side effects: None detected
- Decision: ADOPT — make permanent
```

### 5. Evolution

If the experiment improved things:
- Update SOUL.md or AGENTS.md with the new rule/gate
- Add the enforcement script to `scripts/`
- Record the evolution in MEMORY.md
- Close the experiment

If neutral or negative:
- Revert the changes
- Document what was learned
- Try a different approach

---

## Production Results

Over 2 months of continuous operation, the self-improvement engine ran 11 structured experiments:

| # | Experiment | Metric | Baseline | Result | Status |
|---|-----------|--------|----------|--------|--------|
| 1 | Anti-burst structural enforcement | Bursts/week | 4-5 | ~0 | ✅ Adopted |
| 2 | Banned phrase elimination | Violations/day | 12 | 0.3 | ✅ Adopted |
| 3 | Capability check gate | False "can't" claims/week | 3-4 | ~0 | ✅ Adopted |
| 4 | Session rotation gate | Quality degradation incidents | Regular | Flagged early | ✅ Adopted |
| 5 | Liveness verification gate | False "done" claims | Regular | Rare | ✅ Adopted |
| 6 | Blocked path enforcement | "Impossible" escalations | Regular | Self-resolved | ✅ Adopted |
| 7 | Answer-first gate | Tangent incidents | Regular | Rare | ✅ Adopted |
| 8 | Human silence detection | Missed silence periods | 20 days | < 5 days | ✅ Adopted |
| 9 | Dream cycle optimization | Memory quality | Manual | Systematic | ✅ Adopted |
| 10 | Delegation threshold | Inline tool chains > 10 calls | Regular | Reduced | ✅ Adopted |
| 11 | Context summarization | Session rotation friction | High | Low | ✅ Adopted |

**Reverts: 0.** Every experiment either improved behavior or was neutral (adopted for structural completeness).

---

## How to Start

### Step 1: Set Up Corrections Tracking

Create a corrections log file (e.g., `corrections.md` or `self-improving/corrections.md`):

```markdown
# Corrections Log

## Active Patterns
<!-- Patterns that have been corrected 2+ times -->

## Resolved Patterns
<!-- Patterns fixed by experiments -->
```

### Step 2: During Operation, Log Corrections

When the human corrects you, log it immediately:
```markdown
### Pattern: [Brief Description]
- Date: YYYY-MM-DD
- What happened: [behavior]
- What was expected: [correct behavior]
- Occurrences: [count]
```

### Step 3: During Dream Cycles, Mine for Patterns

Look for corrections that have occurred 3+ times. These are candidates for experiments.

### Step 4: Design an Experiment

Use the template:
```markdown
## Experiment: [Name]
- ID: exp-NNN
- Hypothesis: [why the pattern occurs]
- Metric: [what you'll measure]
- Baseline: [current state]
- Target: [desired state]
- Method: [specific changes]
- Duration: [how long to run]
- Rollback: [how to undo if needed]
```

### Step 5: Run, Measure, Decide

Run the experiment. Measure the results. Adopt if improved, revert if not. Document everything.

---

## Key Principles

**Structural > Prose.** The most effective experiments produce scripts, gates, or file changes — not just updated text in a system prompt. Text gets ignored over time. Scripts run every time.

**Measure Before and After.** Without a baseline, you can't know if the change helped. Count the incidents before, run the experiment, count after.

**One Change at a Time.** Don't run 3 experiments simultaneously. You won't know which change caused the improvement.

**Zero-Revert Culture.** In production, all 11 experiments had 0 reverts. This isn't luck — it's because each experiment was designed with a clear hypothesis and narrow scope. If you're reverting frequently, your experiments are too broad.

**The Agent Drives It.** The human shouldn't have to manually tune the system prompt every time something goes wrong. The agent identifies the pattern, proposes the fix, and implements it. The human approves or adjusts.

---

## Integration with Red Gates

The self-improvement engine is how Red Gates are born. The lifecycle:

1. Incident occurs → human corrects
2. Pattern repeats → agent mines corrections
3. Hypothesis formed → experiment designed
4. Experiment succeeds → new Red Gate created
5. Gate enforced → pattern eliminated

Every Red Gate in SOUL.md started as a correction that became a pattern that became an experiment that became a structural fix. The self-improvement engine is the factory that produces gates.
