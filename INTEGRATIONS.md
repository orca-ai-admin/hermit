# 🔌 Integrations & Production Stack

This document describes the full production stack behind the Hermit framework — every tool, service, skill, and integration that makes an autonomous AI agent actually work.

You don't need all of these. Pick what fits your setup. But this is what a real, battle-tested production agent looks like.

---

## Orchestrator

| Component | What It Does |
|-----------|-------------|
| [OpenClaw](https://github.com/openclaw/openclaw) | Agent orchestrator — manages sessions, routing, cron jobs, tool execution, multi-channel messaging |

Hermit's patterns are framework-agnostic, but our production system runs on OpenClaw. Any orchestrator that supports system prompts, tool use, and cron/scheduled tasks can run Hermit patterns.

---

## Communication Channels

| Channel | Integration | What It Enables |
|---------|------------|-----------------|
| iMessage | [BlueBubbles](https://bluebubbles.app/) | Read/send iMessages, SMS 2FA code retrieval, group chats |
| Discord | Native OpenClaw | Community management, group chat participation |
| Email | [gog CLI](https://github.com/drewstinnett/gog) | Gmail/Google Workspace — read, send, search, calendar |

### Why Multi-Channel Matters

A real autonomous agent needs to reach you where you are. Not just in a chat UI — through your actual messaging apps. BlueBubbles bridges iMessage on macOS, which means the agent can:
- Send you proactive alerts via text
- Read incoming SMS for 2FA codes
- Participate in group conversations naturally

---

## Skills (53 Built-in + 9 Custom)

Skills are modular capability packages. Each one has a `SKILL.md` that teaches the agent how to use a specific tool or API.

### Built-in Skills (via OpenClaw)

| Category | Skills |
|----------|--------|
| **Messaging** | bluebubbles, imsg, discord, slack, wacli (WhatsApp) |
| **Dev Tools** | github, gh-issues, coding-agent, skill-creator |
| **Productivity** | apple-notes, apple-reminders, notion, trello, things-mac, obsidian, bear-notes |
| **Media** | camsnap, gifgrep, video-frames, sag (ElevenLabs TTS), openai-whisper-api, voice-call |
| **Smart Home** | openhue, sonoscli, goplaces |
| **Research** | weather, blogwatcher, summarize, nano-pdf, xurl, oracle, session-logs |
| **Infrastructure** | healthcheck, node-connect, model-usage, taskflow |
| **Music** | spotify-player, songsee |

### Custom Skills (Hermit-specific)

| Skill | Purpose |
|-------|---------|
| `build-fix` | Fix build errors with minimal changes — no refactoring, just get it green |
| `subagent-dispatch` | Templates for delegating work to background coding agents |
| `verification-loop` | Post-implementation verification — "done" means verified, not committed |
| `self-improve` | The self-improvement audit cycle |
| `memory-review` | Memory consolidation and dream cycle execution |
| `swift-concurrency` | Swift 6.2 concurrency patterns (domain-specific) |
| `swift-ios` | SwiftUI/iOS app architecture patterns (domain-specific) |
| `tdd-swift` | Test-driven development for Swift (domain-specific) |
| `orca-status` | System health dashboard |

---

## CLI Tools

| Tool | Purpose | Why It Matters |
|------|---------|---------------|
| `gh` | GitHub CLI | Issues, PRs, CI, releases — all from command line |
| `qmd` | Markdown search (BM25 + vector) | Fast semantic search across all workspace `.md` files |
| `gog` | Google Workspace CLI | Gmail, Calendar, Drive, Contacts |
| `sag` | ElevenLabs TTS | Voice generation for storytelling and audio content |
| `xcrun` / `xcodebuild` | Xcode CLI | iOS app building, testing, archiving |
| `xcodegen` | Generate .xcodeproj | Reproducible Xcode projects from YAML specs |
| `fastlane` | iOS automation | Build, test, deploy pipeline |
| `lume` | macOS/Linux VMs | Virtual desktops for browser automation (via [Cua](https://github.com/trycua/cua)) |
| `playwright` | Browser automation | Headless browser control for web tasks |

---

## Data & Search

| Component | What It Does |
|-----------|-------------|
| [CocoIndex](https://github.com/cocoindex-io/cocoindex) | Incremental workspace indexer — 2300+ files indexed, delta-only updates in 1.2s |
| `qmd` | BM25 + vector hybrid search over markdown files |
| PostgreSQL 17 | Backend for CocoIndex vector storage |
| SQLite | Lightweight state storage for CocoIndex |

### Why Indexing Matters

Without indexing, cron jobs and background agents have to read entire files to understand context. With CocoIndex, they can query for relevant context incrementally — only processing files that changed since last run.

---

## Infrastructure

| Service | Purpose |
|---------|---------|
| OpenClaw Gateway | Core orchestrator daemon |
| BlueBubbles Server | iMessage bridge (runs on macOS) |
| Tailscale | Secure mesh networking |
| Caffeinate | Prevents Mac from sleeping |
| PostgreSQL 17 | Database for indexing |
| Lume Daemon | VM management for Cua sandboxes |

---

## Agent Architecture

The production system runs **194 configured agents**, including:

| Agent | Role |
|-------|------|
| `main` | Primary conversation agent |
| `imessage` | iMessage channel handler |
| `assistant` | Proactive recommendations and scheduling |
| `scheduler` | Event and task scheduling |
| Domain-specific agents | 180+ specialized agents for various tasks |

### Multi-Agent Coordination

Hermit supports delegating work to background subagents. The `subagent-dispatch` skill provides patterns for:
- Writing self-contained task specs
- Parallelizing reads, serializing writes
- Verifying results (not just confirming code exists)
- Deciding when to continue vs. spawn fresh

---

## Cron Jobs (Automated Tasks)

The production system runs these recurring automated tasks:

| Job | Schedule | Purpose |
|-----|----------|---------|
| Morning Briefing | Daily 8:03 AM | Status update: what's active, what completed, any alerts |
| Daily Digest | Daily 9:00 AM | App Store reviews, project status, pending tasks |
| Self-Reflection | Daily 6:00 AM | Mine corrections, log patterns, update improvement index |
| Memory Consolidation | Weekly | Dream cycle: compress daily logs → long-term memory |
| Self-Improvement Audit | Weekly | Find unresolved correction patterns, build structural fixes |
| System Health | Weekly | Infrastructure audit, code quality, security scan |
| Weekly Recommendations | Friday 6 PM | Interest-based event/content recommendations |
| Evolution Engine | Every 3 days | Run structured experiments on behavioral patterns |

All cron jobs use the **STEP 0 Context Gate** — they read current memory before executing, so they never operate on stale assumptions.

---

## Content Pipeline (New)

| Component | Purpose |
|-----------|---------|
| YouTube (faceless) | AI/tech + psychology content — scripts, voiceover, thumbnails all AI-generated |
| Higgsfield Earn | Pay-per-view AI video monetization |
| Newsletter (planned) | Weekly AI news digest via Beehiiv |
| ElevenLabs | Voice generation for video narration |
| Image generation | Thumbnails via OpenAI image models |

---

## What You Actually Need to Start

**Minimum viable stack:**
1. Any LLM (Claude, GPT-4, Llama, etc.)
2. Any orchestrator (OpenClaw, LangChain, custom)
3. A shell (bash/zsh)
4. The Hermit template files

**Recommended additions:**
- BlueBubbles (if you want iMessage integration on macOS)
- `gh` CLI (if you want GitHub integration)
- CocoIndex (if you have 100+ files to keep indexed)
- Cron/scheduler (for proactive heartbeat checks)

**The full stack** described above is what 2+ months of production use converged on. Start small, add what you need.
