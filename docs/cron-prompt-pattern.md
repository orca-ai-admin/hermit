# Cron Prompt Pattern

How to write prompts for isolated cron jobs that wake up with zero context, so they don't chase stale goals or send irrelevant updates.

## The Problem

Cron jobs are stateless. Each execution starts from nothing — no conversation history, no memory of previous runs, no awareness of what changed since the job was written. The prompt is their entire world.

This creates a specific failure mode: **stale execution**. A cron job written to monitor a price target keeps running after the purchase was made. A briefing job reports on a project that was cancelled last week. A health check alerts on a service that was intentionally taken offline.

Without a context gate, cron jobs operate on the assumptions baked into their prompt at creation time. The world moves on; the cron job doesn't.

**Real failure modes:**
- Price monitor keeps alerting after the item was bought
- Daily briefing reports on a project that was shelved a week ago
- Deployment checker watches a repo that was archived
- Meeting prep job fires for a meeting that was cancelled
- Reminder job sends a reminder for a task that was completed

## The STEP 0 Pattern

Every cron job prompt starts with a context gate — a mandatory first step that reads current workspace memory before doing anything else.

```markdown
## STEP 0 — CONTEXT GATE (run first, before anything else)

Read MEMORY.md and the last 2 days of memory files at memory/.
Understand the current situation, active projects, and recent changes.
If this task is no longer relevant (goal achieved, project cancelled, context changed),
reply TASK_OBSOLETE and stop.
```

This goes **before** any task-specific instructions. The agent reads current state, evaluates whether the job still makes sense, and bails out if it doesn't.

### Why STEP 0 and Not "Check Context"

Calling it "STEP 0" (not "Step 1") signals that it's a prerequisite, not part of the task. It runs before the task even begins. This matters psychologically for the model — it frames context-loading as a gate to pass through, not a step to rush past.

### The TASK_OBSOLETE Bail-Out

When a cron job determines it's no longer relevant, it should emit a clear signal:

```
TASK_OBSOLETE: Price target for Widget X was achieved on 2026-05-01 (purchased per memory/2026-05-01.md).
This monitoring job is no longer needed. Recommend removing from cron schedule.
```

This signal can be caught by the orchestrator to:
- Disable the cron job automatically
- Notify the user that a scheduled task self-terminated
- Log the obsolescence for audit

## Rules

### 1. STEP 0 Goes BEFORE Task-Specific Instructions

```markdown
# ✅ Correct order

## STEP 0 — CONTEXT GATE
Read MEMORY.md and last 2 days of memory/...
If no longer relevant, reply TASK_OBSOLETE and stop.

## STEP 1 — Check Current Price
Query the API for Widget X pricing...

## STEP 2 — Compare and Alert
If price < $50, send notification...
```

```markdown
# ❌ Wrong order

## STEP 1 — Check Current Price
Query the API for Widget X pricing...

## STEP 2 — Compare and Alert
If price < $50, send notification...

## STEP 3 — Check if still relevant
Read MEMORY.md...
```

In the wrong order, the job has already done its work (API calls, notifications) before checking whether it should have run at all.

### 2. Goal-Oriented Jobs MUST Include TASK_OBSOLETE

Any job tracking toward a specific outcome needs the bail-out:

```markdown
## STEP 0 — CONTEXT GATE
Read MEMORY.md and last 2 days of memory/.
This job monitors [specific goal]. If the goal has been achieved,
the project cancelled, or the context changed such that this monitoring
is no longer needed, reply TASK_OBSOLETE with a brief explanation and stop.
```

### 3. Reporting Jobs Use Context to Skip Stale Topics

Briefings and digests don't need TASK_OBSOLETE — they always run. But they use STEP 0 context to ensure relevance:

```markdown
## STEP 0 — CONTEXT GATE
Read MEMORY.md and last 2 days of memory/.
Note: active projects, recent completions, current priorities.
Use this context to ensure your briefing covers relevant topics
and skips anything that's been resolved or deprioritized.
```

### 4. Maintenance Jobs Always Run but Use Context for Awareness

Health checks, cleanup tasks, and infrastructure monitors always execute. They still benefit from STEP 0 for awareness:

```markdown
## STEP 0 — CONTEXT GATE
Read MEMORY.md and last 2 days of memory/.
Note any infrastructure changes, planned outages, or service migrations
that might affect the health checks below.
```

This prevents false alarms when a service is intentionally down for migration.

## Types of Cron Jobs

### Goal Trackers

**Most vulnerable to staleness.** These monitor toward a specific outcome and should self-terminate when the goal is achieved.

**Examples:**
- Price monitors ("alert when Widget X drops below $50")
- Stock trackers ("notify when AAPL hits $200")
- Availability watchers ("alert when concert tickets go on sale")
- Build monitors ("notify when CI goes green on the release branch")

**Template:**
```markdown
## STEP 0 — CONTEXT GATE
Read MEMORY.md and last 2 days of memory/.
This job monitors [GOAL]. If [GOAL] has been achieved, is no longer desired,
or the context has changed, reply TASK_OBSOLETE and stop.

## STEP 1 — Check Current State
[API call, web scrape, command to check current state]

## STEP 2 — Evaluate
If [CONDITION MET]:
  - Send notification to [CHANNEL] with: [MESSAGE FORMAT]
  - Write to memory/[DATE].md: "[GOAL] achieved at [TIME]"
If [CONDITION NOT MET]:
  - Reply with current state for logging
  - No notification
```

### Reporting Jobs

**Need context to be relevant.** These run on a schedule and produce summaries, briefings, or digests.

**Examples:**
- Morning briefings ("daily summary of calendar, weather, priorities")
- Weekly digests ("what happened this week across projects")
- Activity summaries ("GitHub activity across watched repos")

**Template:**
```markdown
## STEP 0 — CONTEXT GATE
Read MEMORY.md and last 2 days of memory/.
Identify: active projects, current priorities, recent changes, upcoming events.
Use this context to make the briefing relevant and skip stale topics.

## STEP 1 — Gather Data
[Calendar check, email scan, GitHub activity, weather, etc.]

## STEP 2 — Compose Briefing
Structure:
- 🗓 Today's schedule (next 24-48h)
- 📧 Important messages/emails since last briefing
- 📋 Active project updates
- ⚠️ Anything that needs attention
- 🌤 Weather (if relevant)

Deliver to [CHANNEL].
Skip sections with nothing new. Don't pad with filler.
```

### Maintenance Jobs

**Always run**, but context helps avoid false alarms and unnecessary work.

**Examples:**
- Health checks ("verify all services are running")
- Cleanup tasks ("delete temp files older than 7 days")
- Backup verification ("confirm last backup completed")
- Certificate expiry checks ("alert if SSL certs expire within 30 days")

**Template:**
```markdown
## STEP 0 — CONTEXT GATE
Read MEMORY.md and last 2 days of memory/.
Note any planned outages, migrations, or infrastructure changes
that might affect the checks below.

## STEP 1 — Run Checks
[Service health, disk usage, backup status, cert expiry, etc.]

## STEP 2 — Report
If all checks pass: brief "all clear" log entry
If issues found:
  - Severity assessment (critical / warning / info)
  - Affected services
  - Recommended action
  - Alert to [CHANNEL] if critical

Context note: If a service is intentionally down (per STEP 0 context),
mark as EXPECTED_DOWN, not as an outage.
```

## Advanced Patterns

### Chained Context

For jobs that build on previous runs, include a "last run" check:

```markdown
## STEP 0 — CONTEXT GATE
Read MEMORY.md and last 2 days of memory/.
Also check memory/cron/[JOB_NAME]-last-run.md for previous run state.
If this task is obsolete, reply TASK_OBSOLETE.

## STEP 1 — Delta Check
Compare current state against last run state.
Only process/report changes since the last run.

## STEP N — Save Run State
Write current state to memory/cron/[JOB_NAME]-last-run.md for next execution.
```

### Escalation Gates

For jobs that might need to wake up a human:

```markdown
## Escalation Rules
- INFO: Log only, no notification
- WARNING: Notification to monitoring channel
- CRITICAL: Direct message to on-call person
- Only escalate to CRITICAL if the issue persists across 2+ consecutive runs
  (check memory/cron/[JOB_NAME]-last-run.md for previous status)
```

This prevents flapping alerts — a single failed health check doesn't page anyone; two consecutive failures do.

### Self-Disabling Jobs

For goal trackers that should clean up after themselves:

```markdown
## On TASK_OBSOLETE
If this job is obsolete:
1. Reply TASK_OBSOLETE with reason
2. Write to memory/[DATE].md: "Cron job [NAME] self-terminated: [REASON]"
3. If possible, disable the cron entry (write disable flag to memory/cron/[NAME]-disabled)
```

The orchestrator checks for disable flags before executing scheduled jobs, completing the self-termination cycle.
