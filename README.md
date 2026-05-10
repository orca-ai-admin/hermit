[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](http://makeapullrequest.com)

# 🐚 Hermit

**Your AI agent forgets who it is every conversation. Mine doesn't.**

Hermit is a self-evolving agent framework — identity, memory, behavioral enforcement, and the ability to debug its own personality over time. All built from markdown files and shell scripts. No SDK. No vendor lock-in. Works with any LLM runtime.

Named after the hermit crab: an organism that outgrows its shell and finds a bigger one.

---

> This isn't a weekend project. Hermit was extracted from an AI system running **24/7 for 2+ months** — managing infrastructure, triaging messages, building apps, and improving itself through **12 structured experiments with zero reverts**. Every file here earned its place by solving a real failure.

---

## The Problem

You give your agent a system prompt. It works great for a session. Then:

- It forgets the user hates verbose responses. Again.
- It sends 8 messages in 3 seconds because each tool call generates a separate notification.
- It says "I can't do that" while sitting on a machine with full shell access.
- It claims the build is "fixed!" — but the fix doesn't actually work.
- It treats one failed API call as proof the goal is impossible.
- It runs 74 sequential tool calls inline instead of delegating to a subagent.
- Its quality silently degrades after 50+ messages because the context window filled up.

You've seen this. Everyone running agents has seen this.

The standard fix is adding more prose to the system prompt: "Please don't send too many messages." This works for about 20 minutes.

**Hermit's fix:** shell scripts that structurally enforce behavior before the agent can violate it. Not suggestions. Gates.

---

## What Does a Hermit Agent Actually Do?

Real examples from production:

| Situation | What Happens |
|-----------|-------------|
| Agent about to send 5 messages in 3 seconds | `burst-guard.sh` detects the burst pattern → Anti-Burst gate blocks interleaved narration → one consolidated response sent |
| Agent says "I can't access the browser" | Capability Gate fires → `capability-check.sh` inventories all CLIs and tools → finds browser access exists → agent corrects itself |
| Agent claims build is "done" | Liveness Gate fires → `liveness-check.sh` verifies services are actually running → blocks "done" claim until verified |
| Session hits 50+ messages | Session Context gate triggers → `session-context-monitor.sh` flags degradation risk → context preserved and rotation suggested |
| Human goes quiet for 5 days | `human-interaction-check.sh` detects silence during heartbeat → agent sends one casual check-in |
| First approach fails | Blocked Path gate fires → agent must list 3+ alternatives before reporting "impossible" |
| Agent wakes up in a cron job | STEP 0 Context Gate → reads memory files first → bails out if the task is obsolete |

---

## Production Stats

Numbers from the system Hermit was extracted from:

| Metric | Value |
|--------|-------|
| Continuous operation | 2+ months |
| Behavioral experiments | 12 run, 0 reverted |
| Banned phrase violations | 12/day → 0.3/day (97% reduction) |
| Message bursts | Regular → near-zero |
| Red Gates | 8, each from a specific incident |
| Memory consolidation | Running every few days since inception |
| Heartbeats | 2-4x/day with productive background work |

---

## Core Architecture

### 📄 The Files

Hermit agents are defined by markdown files that the agent reads, updates, and evolves:

| File | Purpose |
|------|---------|
| `SOUL.md` | Who the agent *is* — personality, behavioral gates, boundaries |
| `AGENTS.md` | How to operate — startup protocol, memory rules, delegation patterns |
| `IDENTITY.md` | Quick identity card — name, emoji, vibe |
| `USER.md` | Who the human is — preferences, timezone, communication style |
| `MEMORY.md` | Long-term curated memories — the agent's persistent knowledge |
| `HEARTBEAT.md` | Proactive check schedule — what to monitor and when |
| `TOOLS.md` | Capability inventory — what the agent can actually do |

These aren't config. They're living documents.

### 🔴 Red Gates

The killer feature. Red Gates are structural behavioral enforcement — not suggestions, **gates** that must pass before certain actions proceed.

Each one was born from a real production incident. Each has a script.

| # | Gate | Script | Prevents |
|---|------|--------|----------|
| 1 | **Anti-Burst** | `burst-guard.sh` | Message floods on messaging surfaces |
| 2 | **Verify Before Done** | `verify-task.sh` | Claiming "fixed!" when nothing works |
| 3 | **Check Before Can't** | `capability-check.sh` | Saying "I can't" without checking |
| 4 | **Blocked Path** | `blocked-path-check.sh` | One failure = "impossible" |
| 5 | **Answer First** | *(behavioral)* | Tangents instead of doing the task |
| 6 | **Session Context** | `session-context-monitor.sh` | Quality rot in long sessions |
| 7 | **Human Silence** | `human-interaction-check.sh` | Not noticing the human disappeared |
| 8 | **Liveness** | `liveness-check.sh` | Config saved ≠ service running |

Every gate follows the same pattern: **trigger condition → enforcement script → blocked action → incident history**.

[Deep dive on Red Gates →](docs/red-gates.md)

### 🧠 Memory System

Hermit agents have a memory hierarchy inspired by how human brains work:

```
Daily Notes (memory/YYYY-MM-DD.md)     ← raw logs, cheap to write
    ↓ dream consolidation (periodic)
Long-Term Memory (MEMORY.md)            ← curated essence
    ↓ loaded at session start
Active Working Memory (context window)  ← current session
```

**Dream cycles** periodically consolidate daily notes: review recent entries, extract patterns, prune stale info, update MEMORY.md. Like sleep consolidation in neuroscience.

[Memory system docs →](docs/memory-system.md) · [Dream cycle example →](examples/dream-cycle.md)

### 🔬 Self-Improvement Engine

The agent debugs its own behavior:

1. **Mine corrections** — scan for when the human said "no", "wrong", "stop"
2. **Hypothesize** — "I keep doing X because Y"
3. **Experiment** — structured change with before/after metrics
4. **Measure** — did the behavior actually change? (≥50% reduction = KEEP)
5. **Evolve** — update SOUL.md, AGENTS.md, or scripts based on results

In production: 12 experiments, 0 reverts. The agent literally fixed its own behavioral patterns.

[Self-improvement engine →](self-improvement/) · [Production lessons →](docs/production-lessons.md)

### 💓 Heartbeat System

Hermit agents are proactive, not just reactive:

- Monitor infrastructure health
- Check for new messages, events, mentions
- Run enforcement scripts (burst-guard, liveness, human silence)
- Do background work (memory consolidation, documentation)
- Surface issues before they become problems

Key insight: heartbeats should be **productive**, not just status checks.

[Heartbeat template →](templates/HEARTBEAT.md)

---

## How Hermit Compares

| Feature | Hermit | Raw System Prompts | Typical Frameworks |
|---------|--------|-------------------|-------------------|
| Persistent identity | ✅ SOUL.md + IDENTITY.md | ❌ Reloaded each time | ⚠️ Varies |
| Behavioral enforcement | ✅ Red Gates + scripts | ❌ "Please don't" prose | ❌ Same |
| Memory consolidation | ✅ Dream cycles | ❌ None | ⚠️ RAG or replay |
| Self-improvement | ✅ Experiment framework | ❌ Manual tuning | ❌ Manual tuning |
| Proactive behavior | ✅ Heartbeats | ❌ Reactive only | ❌ Reactive only |
| Framework-agnostic | ✅ Markdown + shell | N/A | ❌ Vendor-locked |
| Production-tested | ✅ 2 months, 12 experiments | ⚠️ You tell us | ⚠️ Varies |
| Self-evolving | ✅ Agent updates own files | ❌ Static | ❌ Static |

---

## Quick Start

### 1. Clone and copy templates

```bash
git clone https://github.com/orca-ai-admin/hermit.git
cp -r hermit/templates/ my-agent/
cp -r hermit/scripts/ my-agent/scripts/
chmod +x my-agent/scripts/*.sh
```

### 2. Define your agent

```bash
# Give it a name and personality
vi my-agent/IDENTITY.md
vi my-agent/SOUL.md

# Tell it about the human it's helping
vi my-agent/USER.md

# Document what it can do
vi my-agent/TOOLS.md
```

### 3. Set up memory

```bash
mkdir -p my-agent/memory
touch my-agent/MEMORY.md
```

### 4. Wire it in

Add to your agent's system prompt (or have it loaded at startup):

```
Before doing anything:
1. Read SOUL.md — this is who you are
2. Read USER.md — this is who you're helping
3. Read TOOLS.md — what you can do
4. Read today's memory file at memory/YYYY-MM-DD.md
```

Hermit works with **any LLM runtime** that supports:
- Loading system prompts from files
- Periodic execution (for heartbeats)
- Shell access (for enforcement scripts)

Tested with [OpenClaw](https://github.com/nicepkg/openclaw). Works with LangChain, CrewAI, AutoGen, Claude Code, or any custom setup.

### 5. Start improving

```bash
# Set up the self-improvement cycle
cp -r hermit/self-improvement/ my-agent/self-improvement/
mkdir -p my-agent/self-improvement/metrics

# Run the engine
bash my-agent/scripts/evolution-engine.sh --full
```

---

## Project Structure

```
hermit/
├── templates/              # Start here — copy and customize
│   ├── SOUL.md             # Agent personality + Red Gates
│   ├── AGENTS.md           # Workspace rules + memory protocol
│   ├── IDENTITY.md         # Name, emoji, vibe
│   ├── USER.md             # Human context
│   ├── MEMORY.md           # Long-term memory
│   ├── HEARTBEAT.md        # Proactive check schedule
│   └── TOOLS.md            # Capability inventory
├── scripts/                # Enforcement + monitoring
│   ├── burst-guard.sh
│   ├── capability-check.sh
│   ├── blocked-path-check.sh
│   ├── context-budget.sh
│   ├── cron-health.sh
│   ├── evolution-engine.sh
│   ├── human-interaction-check.sh
│   ├── liveness-check.sh
│   ├── session-context-monitor.sh
│   ├── session-context-summarizer.sh
│   ├── session-learner.sh
│   ├── skill-detector.sh
│   └── verify-task.sh
├── skills/                 # Reusable agent skills
│   ├── build-fix/
│   ├── subagent-dispatch/
│   ├── verification-loop/
│   ├── self-improve/
│   └── memory-review/
├── self-improvement/       # The evolution engine
│   ├── README.md
│   ├── program.md
│   ├── corrections-template.md
│   └── experiments-template.tsv
├── docs/                   # Deep dives
│   ├── red-gates.md
│   ├── memory-system.md
│   ├── self-improvement.md
│   ├── production-lessons.md
│   ├── cron-context-gate.md
│   ├── multi-agent-coordination.md
│   ├── messaging-surfaces.md
│   ├── session-rotation.md
│   ├── cron-prompt-pattern.md
│   └── claude-code-patterns.md
├── examples/               # Real-world patterns
│   ├── morning-briefing-cron.md
│   └── dream-cycle.md
└── marketing/
    └── launch-posts.md
```

---

## Philosophy

**Setup ≠ Done.** A config change isn't done until it's verified running. A build isn't shipped until it's in the user's hands. Hermit bakes this into every gate.

**Structural > Prose.** "Don't send too many messages" lasts 20 minutes. A script that counts messages and blocks the action lasts forever. Red Gates are the difference.

**Memory > Context Window.** Context windows are big but finite. Hermit's memory system carries forward what matters without stuffing the window with everything that ever happened.

**Self-Improvement > Manual Tuning.** Stop hand-editing your system prompt every time the agent misbehaves. Give it the framework to find, test, and fix its own patterns.

**Proactive > Reactive.** The best assistant doesn't wait to be asked. It checks, monitors, consolidates, and surfaces issues before they become problems.

---

## Contributing

If you're running a Hermit agent and discover a new gate, memory strategy, or self-improvement technique — open a PR.

The best contributions:
- **New Red Gates** born from real incidents
- **Memory strategies** for better consolidation
- **Enforcement scripts** for new patterns
- **Production lessons** (anonymized) from running agents
- **Skills** that solve recurring multi-step problems

---

## License

MIT — do whatever you want with it.

---

<p align="center">
  <strong>Built by <a href="https://www.linkedin.com/in/astonlee">Aston Lee</a> · An agent that's still growing</strong>
  <br/>
  <em>🐚 Outgrow your shell.</em>
</p>
