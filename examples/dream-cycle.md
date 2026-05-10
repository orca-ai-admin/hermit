# Example: Dream Cycle

A dream cycle is the agent's periodic memory consolidation — reviewing recent daily notes, extracting patterns, and updating long-term memory.

Named after sleep consolidation in neuroscience: during sleep, the brain replays experiences and transfers important patterns from short-term to long-term storage.

---

## When to Run

- Every 3-5 days (or when daily notes accumulate)
- During a heartbeat with nothing urgent
- After a particularly eventful period
- Before daily notes get so long they're hard to review

---

## The Process

### Step 1: Read Accumulated Daily Notes

```markdown
Reading daily notes from the past 5 days:
- memory/2026-03-11.md
- memory/2026-03-12.md
- memory/2026-03-13.md
- memory/2026-03-14.md
- memory/2026-03-15.md
```

### Step 2: Extract Patterns

Look for:
- **Repeated corrections** → behavioral insights
- **User preferences** discovered through interaction
- **Project decisions** and their rationale
- **Completed tasks** that can be archived
- **Ongoing context** that should persist

### Step 3: Draft Consolidation

Example — given these daily notes:

**memory/2026-03-11.md:**
```markdown
- Deployed auth service v2.1 to staging
- Human prefers updates in bullet points, not paragraphs
- CI pipeline broke — missing env var DATABASE_URL
```

**memory/2026-03-12.md:**
```markdown
- Fixed CI pipeline, added DATABASE_URL to env config
- Human corrected me for sending 5 messages about the CI fix
- Should consolidate updates before sending
- Auth service v2.1 approved for production
```

**memory/2026-03-13.md:**
```markdown
- Deployed auth service v2.1 to production
- Sent single consolidated message about deployment — human said "much better"
- Started work on API rate limiter
- Human mentioned they'll be at a conference Mar 18-22
```

**memory/2026-03-14.md:**
```markdown
- API rate limiter initial implementation done
- Human wants 100 req/min default, 1000 for premium tier
- Almost sent a multi-message update, caught it in time
- Need to set up monitoring for rate limiter
```

**memory/2026-03-15.md:**
```markdown
- Rate limiter monitoring configured
- Liveness check passing on all services
- Dream cycle due — 5 days of notes accumulated
```

### Step 4: Update MEMORY.md

```markdown
# MEMORY.md — Long-Term Memory

_Last consolidated: 2026-03-15_

## User Memories
- Prefers bullet points over paragraphs for updates
- Will be at a conference Mar 18-22 (plan for reduced availability)
- Confirms improvements explicitly ("much better") — positive signal to track

## Feedback & Corrections
- Anti-burst: CRITICAL priority. Corrected 2026-03-12 for sending 5 messages.
  Fixed by consolidating updates. Confirmed working 2026-03-13.
  Pattern: caught and self-corrected 2026-03-14. Gate is working.

## Project Context
- Auth service: v2.1 deployed to production (2026-03-13), stable
- API rate limiter: implemented and monitored
  - Default: 100 req/min, Premium: 1000 req/min
  - Monitoring configured, liveness checks passing
- CI pipeline: Fixed missing DATABASE_URL env var (2026-03-12)

## Reference Pointers
- Rate limiter config: /config/rate-limiter.yaml
- Monitoring dashboard: (add URL when available)

## Behavioral Notes
- Anti-burst gate is effective — self-caught potential violation on 2026-03-14
- Single consolidated messages get positive feedback
- Dream cycle cadence: every 5 days seems right for current activity level
```

### Step 5: Prune Outdated Information

Review existing MEMORY.md entries:
- Remove completed items that are no longer relevant
- Update entries with new information
- Remove contradicted information (e.g., if a preference changed)
- Keep the file focused and scannable

---

## Consolidation Rules

### Always Consolidate
- ✅ User preferences and communication patterns
- ✅ Corrections (especially patterns — these become behavioral insights)
- ✅ Project decisions and their rationale
- ✅ Important dates and deadlines
- ✅ Discovered capabilities or limitations
- ✅ Behavioral self-observations (what's working, what isn't)

### Never Consolidate
- ❌ Raw command outputs or logs
- ❌ Temporary debugging context
- ❌ Information easily found in files (`git log`, `ls`, config files)
- ❌ Secrets, credentials, tokens, or API keys
- ❌ One-time events with no lasting significance

### Consolidation Quality Checks
- Can you act on this memory? (If not, why keep it?)
- Is this already in a file somewhere? (Don't duplicate what `grep` can find)
- Will this matter in 2 weeks? (If not, leave it in daily notes)
- Is the "why" included? (Context decays — record reasoning, not just decisions)

---

## Automation

Dream cycles can be triggered:

1. **Manually** — agent decides during a heartbeat
2. **Scheduled** — cron job every 3-5 days
3. **Threshold-based** — when daily notes exceed N files or total size

For scheduled dream cycles, use the STEP 0 pattern to load context first:

```bash
# Dream cycle cron — every 4 days at 3 AM
0 3 */4 * * /path/to/scripts/dream-cycle.sh
```

The script should:
1. STEP 0: Load SOUL.md, IDENTITY.md, USER.md
2. Read all daily notes since last consolidation
3. Read current MEMORY.md
4. Generate updated MEMORY.md
5. Record dream cycle timestamp

---

## Anti-Patterns

**Over-consolidation:** Moving every detail into MEMORY.md makes it too large and noisy. Be selective.

**Under-consolidation:** Never running dream cycles means MEMORY.md is always stale. Set a cadence.

**Losing the "why":** Writing "switched to GraphQL" without "because REST pagination was causing N+1 queries" loses the context that makes the memory useful.

**Not pruning:** MEMORY.md should shrink as well as grow. Old project context, completed tasks, and outdated preferences should be removed.

**Consolidating secrets:** API keys, passwords, and tokens should never go into MEMORY.md. Use environment variables or secure storage.
