# Cron Context Gate — The STEP 0 Pattern

When an agent runs as a cron job, it wakes up with zero context. No memory of who it is, who it's helping, or what it's supposed to care about.

The result: robotic, context-free outputs that feel like they came from a different agent entirely.

The STEP 0 pattern fixes this.

---

## The Problem

Consider a morning briefing cron job. Without context loading:

```
☀️ Morning Briefing - March 15, 2026

Weather: 62°F, partly cloudy
Calendar: 2 events today
Email: 5 unread messages

Have a nice day!
```

That's useless. It's a weather widget with extra steps. It has no personality, no awareness of what matters to the human, no proactive insights.

Now with STEP 0 context loading:

```
Morning — here's what matters today:

☁️ 62°F, partly cloudy. No rain, good for that outdoor meeting at 2 PM.

📅 Two things on your calendar:
- 10:00 AM: Sprint planning (you mentioned wanting to push back the auth migration)
- 2:00 PM: Coffee with the investor (outdoor, weather looks fine)

📧 5 emails, 1 worth reading: the CI pipeline fix from the team lead.
The rest is newsletters and notifications.

💡 Heads up: that API key expires in 3 days. Might want to rotate it before the weekend.
```

Same data. Completely different value. The difference is context.

---

## The Pattern

### STEP 0: Load Context (Before Everything Else)

Every cron job should start by reading the agent's core files:

```bash
# STEP 0: Context Loading
# The agent reads these files before doing any task-specific work.
# This re-grounds the agent in its identity, user context, and recent memory.

FILES_TO_READ=(
  "SOUL.md"        # Who am I? What are my rules?
  "IDENTITY.md"    # Quick identity reference
  "USER.md"        # Who am I helping? Their preferences?
  "TOOLS.md"       # What can I do?
)

# Also read recent memory
MEMORY_FILES=(
  "memory/$(date '+%Y-%m-%d').md"           # Today's notes
  "memory/$(date -v-1d '+%Y-%m-%d').md"     # Yesterday's notes (macOS)
)
```

### STEP 1+: Actual Task

Only after context is loaded does the agent proceed with the cron job's purpose.

---

## Implementation

### Option A: System Prompt Injection

If your cron job triggers an agent conversation, prepend the file contents to the system prompt:

```bash
#!/usr/bin/env bash
# Morning briefing cron job with STEP 0

WORKSPACE="/path/to/agent/workspace"

# STEP 0: Build context
CONTEXT=""
for file in SOUL.md IDENTITY.md USER.md TOOLS.md; do
  if [[ -f "$WORKSPACE/$file" ]]; then
    CONTEXT+="## $file\n$(cat "$WORKSPACE/$file")\n\n"
  fi
done

# Add recent memory
TODAY=$(date '+%Y-%m-%d')
if [[ -f "$WORKSPACE/memory/$TODAY.md" ]]; then
  CONTEXT+="## Today's Memory\n$(cat "$WORKSPACE/memory/$TODAY.md")\n\n"
fi

# STEP 1: Run the actual task with context
# (Your agent invocation here, with CONTEXT included)
```

### Option B: Agent-Side Loading

If your framework supports it, have the agent read the files itself as the first action:

```
Task: Run morning briefing

STEP 0 (mandatory before any output):
1. Read SOUL.md
2. Read IDENTITY.md  
3. Read USER.md
4. Read TOOLS.md
5. Read memory/YYYY-MM-DD.md (today)

STEP 1: Now generate the briefing with full context awareness.
```

### Option C: Pre-Loaded Sessions

Some frameworks support session templates with pre-loaded context. Configure your cron jobs to use a template that includes the core files.

---

## What STEP 0 Enables

### Personality Consistency
Without STEP 0, the agent speaks differently in cron jobs vs interactive sessions. With it, the voice is consistent — same personality, same quirks, same awareness.

### User Awareness
The agent knows the human's timezone (no "good morning" at midnight), preferences (no verbose reports to someone who likes concise), and current context (mentions relevant ongoing projects).

### Proactive Insights
With memory loaded, the agent can connect dots: "That API key you set up last week expires tomorrow" or "You have a meeting at 2 PM and the weather looks bad — maybe suggest moving indoors."

### Red Gate Compliance
Without SOUL.md loaded, the agent doesn't know about Red Gates. Cron outputs without STEP 0 regularly violate anti-burst, answer-first, and other behavioral rules.

---

## Common Cron Jobs That Need STEP 0

| Job | Why Context Matters |
|-----|-------------------|
| Morning briefing | Personality, user preferences, proactive insights |
| Email triage | Knowing which contacts/topics are important |
| Infrastructure checks | Knowing recent deployments and context |
| Reminders | Tone matching, time awareness |
| Report generation | Formatting preferences, what the human cares about |

---

## Anti-Pattern: Skipping STEP 0

Signs that a cron job is missing context loading:
- Output feels robotic or generic
- Tone doesn't match the agent's personality
- No awareness of user preferences
- Violations of Red Gates (especially anti-burst)
- Outputs that the human ignores because they're not useful

If a cron output would be identical regardless of which human it's for — it's missing STEP 0.

---

See [examples/morning-briefing-cron.md](../examples/morning-briefing-cron.md) for a complete example.
