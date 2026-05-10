# Coding Agent Patterns

Architecture patterns learned from building and operating AI coding agents. These cover memory systems, multi-agent coordination, dream cycles, and skill extraction — the infrastructure that makes a coding agent effective across sessions.

## Memory System

### The Four Memory Types

A closed taxonomy for non-derivable knowledge — things the agent can't reconstruct from the codebase or environment alone.

| Type | What It Stores | Example |
|---|---|---|
| **User** | Facts about the human | Timezone, communication preferences, role, pet peeves |
| **Feedback** | Corrections and confirmations | "Don't use semicolons" → feedback. "Good job on that PR" → feedback |
| **Project** | Context that isn't in code | "We chose Redis over Memcached because of X." Architecture decisions, deployment notes |
| **Reference** | Pointers to external systems | API endpoints, service URLs, credential locations (not credentials themselves) |

**Why a closed taxonomy:** Without categories, memory becomes a dump of random facts. The taxonomy forces the agent to classify each memory, which improves retrieval and prevents bloat.

### MEMORY.md as Index, Not Dump

The main memory file should be concise — a curated index that points to topic-specific files when details are needed.

```markdown
# MEMORY.md

## User
- Prefers concise responses. Low tolerance for filler.
- Timezone: America/Los_Angeles
- See memory/user-preferences.md for detailed communication style notes.

## Feedback
- Never ask "Want me to...?" — state what you'll do or just do it.
- Build verification must include running tests, not just checking file existence.
- See memory/feedback-log.md for full correction history.

## Project
- Auth system uses JWT with Redis session store (decision: 2026-03-15)
- API rate limiting: 100 req/min per user, 1000 req/min per API key
- See memory/architecture-decisions.md for detailed ADRs.

## Reference
- CI: GitHub Actions, config in .github/workflows/
- Staging: https://staging.example.com
- Monitoring: Datadog dashboard "API Health"
```

### What NOT to Save

The memory system is for non-derivable knowledge. Don't store things the agent can look up:

- **Code patterns** — Read the codebase. It's right there.
- **Git history** — `git log` exists. Don't duplicate it in memory.
- **Debugging solutions** — The fix is in the code. If it breaks again, re-debug.
- **Ephemeral state** — "Currently on branch feature/auth" is stale in 10 minutes.
- **File contents** — The files are on disk. Memory should point to them, not copy them.

**Rule of thumb:** If `ls`, `grep`, `git log`, or `cat` can answer the question, don't put it in memory.

### Memory Drift

Memories go stale. The architecture decision from 3 months ago might have been reversed. The user's preferred timezone might have changed. The staging URL might be different.

**Mitigation:**
- Verify memories before acting on them — especially for reference-type memories
- Date-stamp entries so staleness is visible
- Periodic consolidation (see Dream Cycle) prunes outdated entries
- When a memory contradicts current evidence, update the memory

```
# Stale memory:
"API uses JWT tokens (2026-01-15)"

# Current evidence:
grep -r "passport" src/auth/  → OAuth2 strategy, no JWT

# Action: Update memory, don't trust the stale entry
```

## Dream / Memory Consolidation

A periodic process that reviews recent session logs, extracts important patterns, consolidates memories, and prunes stale entries. Named "dream" by analogy with how sleep consolidates human memory.

### Triggers

The dream cycle runs when enough material has accumulated to make consolidation worthwhile:

- **Time-based:** At least 2-3 days since last dream cycle
- **Volume-based:** Several sessions have occurred since last consolidation
- **Manual:** User requests memory cleanup or the agent detects memory bloat

Don't run the dream cycle after every session — it's expensive and most sessions don't produce memory-worthy content.

### Four Phases

#### 1. Orient

Read the current memory state. Understand what's already captured. Check when the last consolidation happened.

```
Read: MEMORY.md, memory/*.md (last 5-7 days)
Goal: Know what's already captured, identify gaps
```

#### 2. Gather

Scan recent session logs for memory-worthy content. Look for:
- New user preferences or corrections
- Architecture decisions
- New tools, services, or access methods discovered
- Repeated patterns (things the agent keeps looking up)
- Feedback (corrections the user made)

```
Scan: Session logs since last dream cycle
Extract: Corrections, decisions, new context, patterns
```

#### 3. Consolidate

Merge new findings into the memory system:
- Update MEMORY.md index entries
- Add new topic files if needed
- Merge related memories (3 separate notes about auth → one auth-decisions.md)
- Resolve contradictions (if two memories conflict, investigate and keep the correct one)

```
Write: Updated MEMORY.md, new/updated topic files
Rule: Consolidate, don't just append
```

#### 4. Prune

Remove stale, redundant, or low-value memories:
- Delete entries that are now derivable from code (post-implementation, the memory about "how we'll implement X" is redundant)
- Remove duplicates created across sessions
- Archive old entries that aren't actively useful but might be historically interesting

```
Remove: Stale entries, duplicates, derivable knowledge
Archive: Historical context that's not actively needed
```

### Lock Mechanism

If the dream cycle is triggered from a scheduled job, use a lock to prevent duplicate runs:

```bash
LOCK_FILE="memory/.dream-lock"

if [ -f "$LOCK_FILE" ]; then
    age=$(($(date +%s) - $(stat -f %m "$LOCK_FILE" 2>/dev/null || stat -c %Y "$LOCK_FILE")))
    if [ "$age" -lt 3600 ]; then
        echo "Dream cycle already running (lock age: ${age}s). Skipping."
        exit 0
    fi
    echo "Stale lock detected (${age}s). Removing and proceeding."
fi

touch "$LOCK_FILE"
trap "rm -f $LOCK_FILE" EXIT

# ... dream cycle logic ...
```

The lock prevents two concurrent heartbeats or cron jobs from both running consolidation, which could cause conflicting writes to memory files.

## Coordinator / Multi-Agent Patterns

### Coordinator = Synthesizer, Not Relay

The coordinator (parent agent) must understand the problem space deeply enough to write precise specs. It is never acceptable to relay one worker's output to another without synthesis:

```
❌ "Researcher found these issues. Builder, fix them based on the researcher's findings."

✅ Coordinator reads researcher's findings, understands the root causes, then writes
   a specific implementation spec: "The N+1 query on line 34 of users.ts needs to be
   replaced with a JOIN. Here's the expected query structure..."
```

The coordinator is the architect of the multi-agent workflow. Workers are specialists executing precise tasks. If the coordinator doesn't understand the problem, the workers won't either.

### Continue vs. Spawn Decisions

| Context | Decision | Rationale |
|---|---|---|
| Worker hit a minor issue, needs adjustment | Continue | Has full error context |
| Task complete, new unrelated task | Spawn fresh | Clean context, no interference |
| Verification of another worker's output | Spawn fresh | Independent perspective |
| Second phase that builds on first phase output | Could go either way | Continue if heavy context; spawn if clean interface |
| Session > 30 messages | Spawn fresh | Context dilution risk |

### Parallelize Reads, Serialize Writes

```
✅ Three workers reading different parts of the codebase:
   Worker A reads src/auth/        ]
   Worker B reads src/api/         ] — parallel, no conflicts
   Worker C reads test/            ]

❌ Two workers modifying the same module:
   Worker A refactors src/auth/session.ts  ]
   Worker B adds logging to src/auth/      ] — sequential only!

✅ Pipeline: output of one feeds into the next:
   1. Researcher investigates → findings.md
   2. Coordinator synthesizes → spec.md
   3. Builder implements from spec.md
   4. Reviewer checks the implementation
```

### Shared Scratchpad

For complex multi-worker tasks, use a shared file as a knowledge base:

```markdown
# /tmp/scratchpad-auth-migration.md

## Known Facts (verified)
- Current auth: JWT with 5-minute expiry (src/auth/jwt.ts:12)
- Session store: Redis at localhost:6379 (config/redis.yml)
- 47 API endpoints check auth (grep -c "requireAuth" src/api/routes/*.ts)

## Open Questions
- [ ] Does the mobile app cache tokens? (Worker B investigating)
- [x] Rate limiting tied to auth? → Yes, per-user via auth token (Worker A confirmed)

## Decisions
- Migrate to OAuth2 with refresh tokens (coordinator decision, 2026-05-09)
- Keep Redis for session store, add refresh token storage
```

Workers read the scratchpad before starting and write their findings to it. The coordinator monitors the scratchpad for cross-worker knowledge sharing.

## Skill Extraction

Turning repeated patterns into reusable skills that the agent can apply across sessions.

### Session-Aware Extraction

Skills emerge from observing what works across multiple sessions. The extraction process:

1. **Scan user messages** for repeated requests ("deploy the app", "review this PR", "check the logs")
2. **Identify patterns** in how the agent successfully handles these requests
3. **Extract the pattern** into a reusable skill definition

### Interactive Refinement

Skill extraction works best as an iterative conversation:

**Round 1 — High-level shape:**
```
"I notice you frequently ask me to deploy the staging environment.
I can create a skill for this. At a high level, it involves:
1. Pull latest from main
2. Run tests
3. Build and push Docker image
4. Update staging deployment
5. Verify health check

Does this capture it?"
```

**Round 2 — Details:**
```
"For the Docker build step, are there any specific build args or
target stages I should include? And for verification — just the
health endpoint, or should I also check specific API routes?"
```

**Round 3 — Per-step specifics:**
```
"Here's the refined deploy skill. I've added the --build-arg
for the commit SHA and the three verification endpoints you mentioned.
One more thing: should this skill auto-roll-back if health checks fail?"
```

**Round 4 — Triggers:**
```
"When should this skill activate? Options:
- Explicit: only when you say 'deploy staging'
- Semi-auto: suggest it when I see a merged PR to main
- Auto: run it on every merge to main via cron"
```

### Rich Skill Format

A complete skill definition includes metadata that helps the agent (and humans) understand when and how to use it:

```yaml
---
name: deploy-staging
description: Build, push, and deploy to staging environment
version: 1.2
triggers:
  - "deploy staging"
  - "push to staging"
  - "update staging"
execution_mode: semi-automatic  # suggest, don't auto-execute
human_checkpoints:
  - before_deploy: "About to deploy {commit_sha} to staging. Proceed?"
  - on_failure: "Health check failed. Roll back to {previous_version}?"
success_criteria:
  - health_endpoint_returns_200
  - version_endpoint_shows_new_commit
  - no_error_logs_in_first_60_seconds
estimated_duration: 3-5 minutes
rollback: automatic_on_health_failure
---

## Steps

### 1. Pull and Test
cd /path/to/project
git pull origin main
npm test

### 2. Build
docker build --build-arg COMMIT_SHA=$(git rev-parse HEAD) -t app:staging .

### 3. Push
docker push registry.example.com/app:staging

### 4. Deploy
kubectl set image deployment/app-staging app=registry.example.com/app:staging

### 5. Verify
curl -f https://staging.example.com/health || exit 1
curl -f https://staging.example.com/version | grep $(git rev-parse --short HEAD)

### 6. Monitor
Watch logs for 60 seconds: kubectl logs -f deployment/app-staging --since=1m
Alert if any ERROR-level log entries appear.
```

**Key fields:**
- **execution_mode:** `automatic` (just do it), `semi-automatic` (suggest and confirm), `manual` (show steps, human executes)
- **human_checkpoints:** Points where the agent pauses for human confirmation before proceeding
- **success_criteria:** Concrete, testable conditions that define "done"
- **rollback:** What happens when success criteria aren't met

### Skill Evolution

Skills aren't static. They evolve as the workflow changes:

- **Track success rate** — if a skill fails frequently, it needs updating
- **Capture variations** — "deploy staging" vs "deploy staging with migrations" might be the same skill with a flag
- **Version skills** — when the workflow changes, bump the version and document what changed
- **Retire skills** — if a workflow is abandoned, archive the skill rather than leaving it active
