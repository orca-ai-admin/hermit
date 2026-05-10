# Self-Improvement Engine

An autonomous behavioral optimization system for AI agents. Agents identify their own failure patterns, design structural interventions, run controlled experiments, and evolve their configuration — without human-driven debugging.

## Why This Exists

Prose rules don't stick. You can write "don't send message bursts" in a config file, and the agent will still send bursts 50 sessions later. The context window is finite, attention degrades, and good intentions evaporate under load.

Structural enforcement works. A gate script that runs before every message, a pre-commit hook that rejects banned patterns, a metric that counts violations — these survive context dilution because they execute outside the model's attention window.

The self-improvement engine is how an agent gets from "prose rules that decay" to "structural enforcement that persists."

## The Cycle

```
Corrections Mining → Hypothesis → Experiment → Measurement → Evolution
```

### 1. Corrections Mining

Every correction from the human gets logged in `corrections.md` with metadata: type, severity, pattern name, root cause. This is raw data — the agent records what went wrong and why, using the human's exact words when possible.

Over time, patterns emerge. The same failure shows up 5 times in 10 days. That's a signal.

### 2. Hypothesis

The agent (or the evolution engine script) identifies the highest-frequency unresolved pattern and designs an intervention. The hypothesis follows a standard format:

> Adding [intervention] will reduce [pattern] from [X] to [Y] because [reasoning]. Root cause: [why the pattern exists].

Good hypotheses target root causes, not symptoms. "Add a reminder to be careful" is a bad hypothesis. "Add a gate script that blocks the action until a check passes" is a good one.

### 3. Experiment

The intervention is implemented: config files modified, scripts added, gates inserted. Each experiment gets a unique ID and is logged in `experiments.tsv` with before-metrics.

Experiments modify real configuration — `SOUL.md`, `AGENTS.md`, enforcement scripts. There's no staging environment. The agent is experimenting on itself in production.

### 4. Measurement

After a waiting period (typically 3 days or 10+ sessions), the analysis script compares before and after metrics. The primary metric is `corrections_from_human` — the number of times the human had to correct the same pattern.

- **≥50% reduction**: KEEP. The experiment worked.
- **<50% reduction**: REVERT. Roll back the changes, try a different approach.
- **Regression**: REVERT immediately. Something got worse.

### 5. Evolution

Successful experiments become permanent. The agent's configuration files, enforcement scripts, and behavioral gates accumulate improvements over time. Failed experiments are reverted cleanly via git.

Then the cycle repeats. New patterns surface. New experiments run. The agent asymptotically approaches zero corrections.

## Production Results

This system has been validated in production across months of continuous operation:

- **11 experiments** completed
- **0 reverts** — every intervention improved or maintained metrics
- **97% reduction** in banned phrase usage (from ~5/session to near-zero)
- **Message burst elimination** — multi-message notification storms reduced to single consolidated responses
- **Capability amnesia fixed** — false "I can't do that" claims eliminated via pre-response gate scripts

The key insight: structural fixes (gate scripts, pre-checks, enforcement hooks) outperform prose rules by orders of magnitude. A rule that says "don't do X" fails under context pressure. A script that blocks X from happening doesn't care about context pressure.

## How It Connects to Hermit

The self-improvement engine sits at the intersection of several Hermit components:

```
corrections.md ──→ evolution-engine.sh ──→ experiments.tsv
                          │
                          ▼
                   SOUL.md / AGENTS.md
                   scripts/*.sh (gates)
                          │
                          ▼
                   Session behavior changes
                          │
                          ▼
                   analyze.sh (metrics)
                          │
                          ▼
                   Experiment evaluation
                          │
                          ▼
                   KEEP or REVERT
```

- **Corrections log** feeds the engine with failure data
- **Evolution engine** identifies patterns and designs interventions
- **SOUL.md / AGENTS.md** are the primary configuration targets — experiments add gates, rules, and enforcement blocks
- **Scripts** (`scripts/*.sh`) implement structural enforcement — capability checks, burst guards, liveness gates
- **Analysis scripts** measure outcomes against baselines
- **Experiments TSV** tracks the full lifecycle of every intervention

## Getting Started

### 1. Set Up the Corrections Log

Copy `corrections-template.md` to `corrections.md` and start logging every correction:

```bash
cp self-improvement/corrections-template.md corrections.md
```

Log entries as they happen. Include type, severity, pattern name, and root cause. The more precise your logging, the better the engine works.

### 2. Configure the Evolution Engine

The evolution engine script (`scripts/evolution-engine.sh`) orchestrates the cycle. It:

- Reads the corrections log and experiments TSV
- Identifies the highest-frequency unresolved pattern
- Checks for pending experiments that need evaluation
- Outputs recommendations for new interventions

Run it manually or wire it into your heartbeat/cron cycle:

```bash
bash scripts/evolution-engine.sh
```

### 3. Track Experiments

Copy `experiments-template.tsv` to `experiments.tsv` and log each experiment:

```bash
cp self-improvement/experiments-template.tsv experiments.tsv
```

Every intervention gets a row. Fill in before-metrics at start, after-metrics at evaluation. The TSV format makes it easy to parse programmatically.

### 4. Run the Analysis

After the waiting period, run your analysis script to compare metrics:

```bash
bash scripts/analyze.sh
```

The output tells you whether each pending experiment should be kept or reverted.

### 5. Iterate

The cycle never stops. As old patterns are resolved, new ones surface. The goal isn't perfection — it's continuous improvement with a monotonically decreasing correction rate.

## Key Principles

1. **Structural > Prose**: A gate script that blocks bad behavior beats a rule that asks nicely.
2. **Metrics > Introspection**: "I already know the answer" after repeating a violation means the model doesn't know. Trust the numbers.
3. **Fixed Evaluator**: Don't change your measurement tool during experiments. That's like changing the scale while dieting.
4. **Small, Targeted Interventions**: One experiment per pattern. Isolate variables.
5. **Revert Cleanly**: Every experiment should be reversible via `git revert`. No tangled dependencies.

## File Reference

| File | Purpose |
|------|---------|
| `corrections-template.md` | Template for the corrections log |
| `experiments-template.tsv` | Template for experiment tracking |
| `program.md` | The full autonomous self-improvement research program |
| `../scripts/evolution-engine.sh` | Orchestrates the improvement cycle |
| `../scripts/analyze.sh` | Measures experiment outcomes |
