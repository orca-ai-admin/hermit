# Autonomous Self-Improvement Program

A continuous research program where AI agents optimize their own behavior through structured experimentation. Inspired by [Karpathy's autoresearch](https://x.com/kaboratokarpathy) concept — but applied to agent behavioral patterns instead of ML model training.

## Core Concept

In ML research, you train a model, measure val_bpb, adjust hyperparameters, and iterate. The model doesn't choose its own hyperparameters.

In agent self-improvement, the agent IS the model AND the researcher. It:

- Identifies its own failure patterns from correction data
- Designs structural interventions (not just "try harder" rules)
- Implements changes to its own configuration
- Measures outcomes against baselines
- Keeps what works, reverts what doesn't

### The Primary Metric

**`corrections_from_human`** — the number of times the human corrects the same behavioral pattern.

This is the agent's equivalent of `val_bpb`. Lower is better. It's externally generated (by the human), resistant to gaming (the agent can't fake fewer corrections), and directly measures what matters (is the agent getting better at its job?).

### The Fixed Evaluator Principle

Never change the measurement tool during an experiment. If you're counting corrections in session logs, keep counting corrections in session logs. Don't switch to self-reported "I think I did well" metrics mid-experiment. That's like changing the scale while dieting.

The evaluator (analysis script + corrections log) stays fixed. The subject (agent configuration) changes.

### Structural > Prose

This is the single most important principle in the program:

| Pattern | Prose Fix (Ineffective) | Structural Fix (Effective) |
|---------|------------------------|---------------------------|
| Message bursts | "Remember to send only one message" | Anti-burst gate: script that counts messages between tool calls, blocks emission if >1 |
| Capability amnesia | "Check your tools before saying you can't" | Capability check script: runs automatically before any response containing "I can't" |
| Permission-seeking | "Don't ask permission, just act" | Banned phrase list + session-level regex enforcement |
| Incomplete verification | "Make sure it actually works" | Liveness gate: script that tests the end result before allowing "done" responses |
| Context dilution | "Be careful in long sessions" | Session length monitor: alerts at 30 messages, blocks new work at 60 |
| Tangent chasing | "Stay on topic" | Answer-first gate: structural rule requiring the asked question be answered before any tangent |

Prose rules decay under context pressure. The longer the session, the more likely a prose rule gets buried under task content and forgotten. Structural fixes execute regardless of context state because they run as external scripts, not in-context instructions.

## The Loop

```
while true:
    metrics = run analyze.sh
    evaluate_pending_experiments(metrics)
    pattern = highest_frequency_unresolved_pattern(metrics, corrections.md)
    intervention = design_structural_fix(pattern)
    implement(intervention)
    commit(workspace, message="experiment: {pattern}")
    log_to_experiments_tsv()
    wait for next trigger
```

### Step by Step

1. **`run analyze.sh`** — Parse session logs and corrections log. Count pattern frequencies. Calculate per-pattern and aggregate correction rates.

2. **`evaluate_pending_experiments`** — Check experiments with status `RUNNING`. If enough time has passed (3+ days or 10+ sessions), compare `metrics_before` to current metrics. Mark as `KEPT` (≥50% improvement) or `REVERTED` (<50% or regression).

3. **`highest_frequency_unresolved_pattern`** — From the corrections log, find the pattern with the most occurrences that doesn't have an active or successful experiment targeting it.

4. **`design_structural_fix`** — This is the creative step. The agent (or a human reviewing the data) designs an intervention. Good interventions are:
   - **Structural**: scripts, gates, hooks — not prose reminders
   - **Targeted**: one pattern per experiment
   - **Measurable**: clear before/after metrics
   - **Reversible**: can be cleanly git-reverted

5. **`implement`** — Modify configuration files (SOUL.md, AGENTS.md), add scripts, insert gates. The changes are live immediately.

6. **`commit`** — Git commit with a descriptive message. This creates the revert point.

7. **`log_to_experiments_tsv`** — Record the experiment ID, date, pattern, intervention type, files modified, hypothesis, and before-metrics.

8. **`wait`** — The loop triggers on heartbeats, cron schedules, or manual invocation. It doesn't need to run continuously.

## Data Sources

### Session Logs (JSONL)

Raw records of every agent session. Each line is a JSON object with timestamp, role, content, and metadata. Used by the analysis script to count behavioral patterns programmatically.

### Corrections Log (`corrections.md`)

Human-curated record of every correction. Each entry includes type, severity, pattern name, root cause, and fix applied. This is the primary input to the improvement cycle.

### Self-Improvement Records

- **`memory.md`** — Running log of what the agent learned, what worked, what didn't
- **`reflections.md`** — Periodic self-assessments and pattern analysis

### Configuration Files (modification targets)

- **`SOUL.md`** — Agent identity, personality, behavioral rules, gates
- **`AGENTS.md`** — Workspace rules, operational procedures, enforcement blocks
- **`scripts/*.sh`** — Enforcement scripts (gate checks, analysis, monitoring)

## Experiment Lifecycle

### Starting an Experiment

1. **Identify the pattern**: Find it in the corrections log. Count occurrences. Confirm it's the highest-priority unresolved pattern.

2. **Design the intervention**: Write a hypothesis in standard format:
   > Adding [intervention] will reduce [pattern] from [X] to [Y] because [reasoning]. Root cause: [why the pattern exists].

3. **Implement**: Modify files. Add scripts. Insert gates. Keep changes minimal and focused.

4. **Commit**: `git commit -m "experiment: [pattern_name] - [brief description]"`

5. **Log**: Add a row to `experiments.tsv` with status `RUNNING` and `metrics_before` populated.

### Evaluating an Experiment

Wait for sufficient data (3+ days or 10+ sessions since implementation), then:

1. Run `analyze.sh` to get current metrics
2. Compare `metrics_after` to `metrics_before` for the targeted pattern
3. Decision:
   - **≥50% decrease in corrections**: → `KEPT` ✅
   - **<50% decrease**: → `REVERTED` ❌ (try a different approach)
   - **Any regression** (corrections increased): → `REVERTED` ❌ (immediately)

### Reverting an Experiment

```bash
# Find the experiment's commit
git log --oneline --grep="experiment: pattern_name"

# Revert it
git revert <commit_hash>

# Update experiments.tsv: status → REVERTED, outcome → description of why
```

Clean reverts are why single-pattern-per-experiment matters. If you bundle 3 interventions in one commit, you can't revert one without affecting the others.

## Pattern Priority Ranking

When multiple patterns need attention, prioritize by:

### 1. Frequency

How often does this pattern appear in the corrections log? A pattern that shows up 12 times in 30 days outranks one that appeared twice.

### 2. User Impact

Corrections that came directly from the human (explicit "don't do that" feedback) outrank system-internal issues. The human's frustration is the signal that matters most.

Scale:
- **High**: Human explicitly corrected the behavior, sometimes multiple times
- **Medium**: Human noticed but didn't strongly react
- **Low**: Agent self-identified via logs, human didn't notice

### 3. Structural Gap

Is there already a fix in place that's failing? A pattern with an existing gate script that still leaks is higher priority than a new pattern with no fix at all — because it means the current structural approach is insufficient and needs redesign.

### Combined Priority Score

```
priority = (frequency × 2) + (user_impact × 3) + (structural_gap × 1.5)
```

Where user_impact: high=3, medium=2, low=1. Structural_gap: existing_fix_failing=3, partial_fix=2, no_fix=1.

## Self-Diagnosis Warning

**"I already know the answer" is not evidence of knowing the answer.**

When an agent violates a rule it has explicitly acknowledged understanding, the natural response is: "I know what I did wrong, I won't do it again." This is unreliable. The model said the same thing before the previous violation.

The failure mode:

1. Agent violates pattern X
2. Human corrects: "Don't do X"
3. Agent responds: "You're right, I know X is wrong, won't happen again"
4. 10 sessions later: Agent violates pattern X again
5. Agent responds: "You're right, I know X is wrong, won't happen again"
6. Repeat

**Trust metrics over introspection.** If `corrections_from_human` for pattern X hasn't decreased, the agent hasn't actually learned — regardless of what it claims. Verbal acknowledgment ≠ behavioral change. Only structural enforcement produces durable behavioral change.

This is analogous to overfitting in ML: the model performs well on training data (acknowledging the rule when asked) but poorly on test data (actual behavior in production sessions).

## Stopping Criteria

None.

The loop runs indefinitely. The goal is to asymptotically approach zero corrections from the human. There is no "done" state — only "better than yesterday."

New patterns will always emerge as:
- The agent takes on new capabilities
- The human's expectations evolve
- Edge cases surface in novel situations
- Context window limitations create new failure modes

The self-improvement engine is a permanent part of the agent's operational loop, not a one-time optimization pass.

## Getting Started

1. **Copy the templates**:
   ```bash
   cp self-improvement/corrections-template.md corrections.md
   cp self-improvement/experiments-template.tsv experiments.tsv
   ```

2. **Start logging corrections** — every human correction gets an entry. Be honest. Be precise.

3. **Run the evolution engine** after accumulating 5-10 corrections:
   ```bash
   bash scripts/evolution-engine.sh
   ```

4. **Design your first experiment** — pick the highest-frequency pattern and build a structural fix.

5. **Measure and iterate** — wait, evaluate, keep or revert, repeat.

The system improves as it accumulates data. Early experiments target obvious, high-frequency patterns. Later experiments tackle subtle edge cases. The correction rate drops. The agent gets better. That's the whole program.
