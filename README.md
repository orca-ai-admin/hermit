# 🐚 Hermit

**Most AI agents forget who they are every conversation. Hermit doesn't.**

Hermit is a self-evolving AI agent framework. It gives your agent identity, memory, behavioral enforcement, and the ability to literally debug its own personality over time.

Named after the hermit crab — an organism that outgrows its shell and finds a bigger one. Your agent starts small. It learns. It evolves. It never forgets who it is.

This isn't a toy. Hermit was extracted from a production AI system that's been running 24/7 for 2+ months — managing infrastructure, sending messages, triaging emails, building apps, and improving itself through 11 structured experiments with zero reverts. Every pattern here earned its place by solving a real problem.

---

## Why Hermit?

Most agent frameworks give you tools and a system prompt. That's a goldfish with a toolbelt.

Hermit gives you:

- **Identity that persists** — Your agent knows who it is across sessions
- **Memory that consolidates** — Daily notes → dream cycles → long-term memory (yes, inspired by neuroscience)
- **Behavioral gates that actually work** — Not "please don't do X" prose. Structural enforcement with scripts that run before the agent can violate rules
- **Self-improvement loops** — The agent mines its own corrections, runs experiments, and evolves its behavior
- **Proactive heartbeats** — Your agent checks on things without being asked

The difference between Hermit and "just a good system prompt" is the difference between a post-it note and a personality.

---

## Core Files

Hermit agents are defined by a set of markdown files. Each one serves a specific purpose:

| File | Purpose |
|------|---------|
| `SOUL.md` | Who the agent *is* — personality, boundaries, behavioral gates |
| `AGENTS.md` | Workspace rules — how to operate, memory protocol, delegation patterns |
| `IDENTITY.md` | Quick identity card — name, emoji, vibe, role |
| `USER.md` | Context about the human — preferences, timezone, communication style |
| `MEMORY.md` | Long-term curated memories — the agent's persistent knowledge |
| `HEARTBEAT.md` | Proactive check schedule — what to monitor and when |
| `TOOLS.md` | Capability inventory — what the agent can actually do |

These aren't config files. They're living documents that the agent reads, updates, and evolves.

---

## 🔴 Red Gates

The killer feature. Red Gates are structural behavioral enforcement patterns — not suggestions, not guidelines, **gates** that must pass before certain actions can proceed.

Each gate was born from a real production incident. Each one has a script that enforces it.

### The 8 Gates

| # | Gate | What It Prevents |
|---|------|-----------------|
| 1 | **Anti-Burst** | Message floods on chat surfaces (each tool-call narration = separate notification) |
| 2 | **Verify Before Done** | Claiming "fixed!" when the fix isn't actually working |
| 3 | **Check Before Can't** | Saying "I can't do that" without checking available capabilities |
| 4 | **Blocked Path** | Treating one failed approach as proof the goal is impossible |
| 5 | **Answer First** | Going on tangents instead of doing the thing that was asked |
| 6 | **Session Context** | Quality degradation in long sessions (>30 messages) |
| 7 | **Human Silence** | Not noticing when the human goes quiet for days |
| 8 | **Liveness** | Reporting infrastructure changes as "done" without verification |

Each gate follows the same pattern:
1. **Trigger condition** — when does this gate activate?
2. **Enforcement script** — what runs to check compliance?
3. **Blocked action** — what can't happen until the gate passes?
4. **Incident history** — why does this gate exist? (with dates)

Read the [deep dive on Red Gates](docs/red-gates.md) for the full story.

---

## Memory System

Hermit agents don't just have memory — they have a memory *hierarchy* inspired by how human brains actually work.

```
Daily Notes (memory/YYYY-MM-DD.md)
    ↓ dream consolidation (periodic)
Long-Term Memory (MEMORY.md)
    ↓ referenced during sessions
Active Working Memory (session context)
```

**Daily notes** are raw logs — what happened, what was decided, what to remember. They're cheap to write and meant to be messy.

**Dream cycles** periodically consolidate daily notes into long-term memory. The agent reviews recent notes, extracts patterns, prunes outdated info, and updates MEMORY.md. Just like sleep consolidation in neuroscience.

**Long-term memory** (MEMORY.md) is curated essence. Not logs — insights. Not everything — the important things. The agent reads this at session start and it shapes every interaction.

Read more: [Memory System](docs/memory-system.md) | [Dream Cycle Example](examples/dream-cycle.md)

---

## Self-Improvement Engine

Here's where it gets interesting. Hermit agents can improve themselves.

The cycle:

1. **Corrections Mining** — Extract patterns from when the human corrected the agent
2. **Hypothesis** — "I keep doing X because of Y"
3. **Experiment** — Structured change with before/after metrics
4. **Measurement** — Did the behavior actually change?
5. **Evolution** — Update SOUL.md, AGENTS.md, or scripts based on results

In production, this system ran 11 experiments over 2 months:
- Banned phrase reduction: 12 violations/day → 0.3/day (97% reduction)
- Message bursts: eliminated through structural enforcement
- Zero reverts — every experiment either improved things or was neutral

The agent literally debugs its own behavior patterns. [Read more](docs/self-improvement.md).

---

## Heartbeat System

Traditional agents are reactive — they wait for you to ask. Hermit agents are proactive.

**Heartbeats** are periodic check-ins where the agent:
- Monitors infrastructure health
- Checks for new emails, calendar events, mentions
- Watches for things that need attention
- Does background work (memory consolidation, documentation updates)
- Reaches out if something important is detected

The key insight: heartbeats should be **productive**, not just status checks. An agent that runs 4 heartbeats/day and does useful background work each time is dramatically more valuable than one that just says "all systems normal."

Read more: [Heartbeat template](templates/HEARTBEAT.md)

---

## Cron Context Gates (STEP 0)

When running automated cron jobs, the agent wakes up with zero context. The STEP 0 pattern ensures it re-grounds itself before taking action:

```
STEP 0: Read SOUL.md → IDENTITY.md → USER.md → TOOLS.md → today's memory
STEP 1: Now do the actual task
```

Without this, cron jobs produce robotic, context-free outputs. With it, they maintain the agent's personality and awareness. Simple pattern, massive difference.

[Full documentation](docs/cron-context-gate.md) | [Example cron job](examples/morning-briefing-cron.md)

---

## Quick Start

### 1. Copy the templates

```bash
git clone https://github.com/usehermit/hermit.git
cp -r hermit/templates/ my-agent/
```

### 2. Customize your agent

Edit the files in `my-agent/`:
- `SOUL.md` — Define personality, boundaries, and Red Gates relevant to your use case
- `IDENTITY.md` — Name your agent, give it a vibe
- `USER.md` — Add context about who it's helping
- `TOOLS.md` — Document what capabilities it has

### 3. Set up memory

```bash
mkdir -p my-agent/memory
touch my-agent/MEMORY.md
```

### 4. Add enforcement scripts

```bash
cp -r hermit/scripts/ my-agent/scripts/
chmod +x my-agent/scripts/*.sh
```

### 5. Wire it into your agent runtime

Hermit is framework-agnostic. The files work with any system that supports:
- System prompts loaded from files
- Periodic execution (for heartbeats)
- Shell access (for enforcement scripts)

Currently tested with [OpenClaw](https://github.com/nicepkg/openclaw), but the patterns apply to any LLM agent framework — LangChain, CrewAI, AutoGen, custom setups, whatever.

---

## Project Structure

```
hermit/
├── README.md
├── LICENSE
├── .gitignore
├── templates/           # Start here — copy and customize
│   ├── SOUL.md
│   ├── AGENTS.md
│   ├── IDENTITY.md
│   ├── USER.md
│   ├── MEMORY.md
│   ├── HEARTBEAT.md
│   └── TOOLS.md
├── scripts/             # Enforcement scripts for Red Gates
│   ├── liveness-check.sh
│   ├── capability-check.sh
│   ├── blocked-path-check.sh
│   ├── burst-guard.sh
│   └── session-context-monitor.sh
├── docs/                # Deep dives
│   ├── red-gates.md
│   ├── memory-system.md
│   ├── self-improvement.md
│   ├── cron-context-gate.md
│   └── production-lessons.md
└── examples/            # Real-world patterns
    ├── morning-briefing-cron.md
    └── dream-cycle.md
```

---

## Philosophy

**Setup ≠ Done.** A config change isn't done until it's verified running. A build isn't shipped until it's in the user's hands. A bug isn't fixed until the fix is confirmed working. Hermit bakes this into every gate.

**Structural > Prose.** Telling an LLM "don't send too many messages" works for about 20 minutes. Giving it a script that counts recent messages and blocks the action? That works forever. Red Gates are the difference.

**Memory > Context Window.** Context windows are big but finite. Hermit's memory system means the agent carries forward what matters without stuffing the context window with everything that ever happened.

**Self-Improvement > Manual Tuning.** Stop hand-editing your system prompt every time the agent does something wrong. Give it the framework to identify, experiment with, and fix its own behavioral patterns.

**Proactive > Reactive.** The best assistant doesn't wait to be asked. It checks in, monitors things, does background work, and surfaces issues before they become problems.

---

## Production Stats

These numbers are from the real system Hermit was extracted from:

- **Uptime:** 2+ months continuous operation
- **Experiments:** 11 structured behavioral experiments, 0 reverts
- **Banned phrase reduction:** 97% (12/day → 0.3/day)
- **Message burst elimination:** From regular occurrence to near-zero
- **Red Gates:** 8 gates, each traced to a specific production incident
- **Memory consolidation cycles:** Running every few days since inception
- **Daily heartbeats:** 2-4x/day with productive background work

---

## vs. Other Frameworks

| Feature | Hermit | Typical Agent Frameworks |
|---------|--------|--------------------------|
| Persistent identity | ✅ SOUL.md + IDENTITY.md | ❌ System prompt reloaded each time |
| Behavioral enforcement | ✅ Red Gates with scripts | ❌ "Please don't" in system prompt |
| Memory consolidation | ✅ Dream cycles | ❌ RAG or full conversation replay |
| Self-improvement | ✅ Experiment framework | ❌ Manual prompt tuning |
| Proactive behavior | ✅ Heartbeat system | ❌ Purely reactive |
| Production-tested | ✅ 2 months, 11 experiments | ⚠️ Varies |
| Framework-agnostic | ✅ Markdown + shell scripts | ❌ Usually tied to specific runtime |

---

## Contributing

This is a living framework. If you're running a Hermit agent and discover a new gate pattern, memory strategy, or self-improvement technique — open a PR.

The best contributions are:
- **New Red Gates** born from real production incidents
- **Memory strategies** that improve consolidation quality
- **Enforcement scripts** for new behavioral patterns
- **Production lessons** (anonymized) from running Hermit agents

---

## License

MIT — do whatever you want with it.

---

<p align="center">
  <strong>Built by <a href="https://github.com/orca-ai-admin">Aston</a> · An agent that's still growing</strong>
  <br/>
  <em>🐚 Outgrow your shell.</em>
</p>
