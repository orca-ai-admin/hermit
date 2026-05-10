# Example: Morning Briefing Cron Job

This example shows a cron job that generates a personalized morning briefing using the STEP 0 pattern.

---

## The Cron Job Script

```bash
#!/usr/bin/env bash
# morning-briefing.sh — Daily morning briefing with STEP 0 context loading
#
# Crontab entry:
#   0 8 * * * /path/to/scripts/morning-briefing.sh
#
# This script demonstrates the STEP 0 pattern: loading agent context
# before performing any task-specific work.

set -euo pipefail

WORKSPACE="/path/to/agent/workspace"

# ═══════════════════════════════════════════════
# STEP 0: CONTEXT LOADING (mandatory)
# ═══════════════════════════════════════════════
#
# The agent wakes up in a cron job with zero context.
# Before doing ANYTHING, it must re-ground itself.

echo "--- STEP 0: Loading Context ---"

CONTEXT=""

# Core identity files
for file in SOUL.md IDENTITY.md USER.md TOOLS.md; do
  filepath="$WORKSPACE/$file"
  if [[ -f "$filepath" ]]; then
    CONTEXT+="## $file"$'\n'"$(cat "$filepath")"$'\n\n'
    echo "  ✅ Loaded $file"
  else
    echo "  ⚠️  Missing $file"
  fi
done

# Recent memory
TODAY=$(date '+%Y-%m-%d')
YESTERDAY=$(date -v-1d '+%Y-%m-%d' 2>/dev/null || date -d 'yesterday' '+%Y-%m-%d')

for memfile in "$WORKSPACE/memory/$TODAY.md" "$WORKSPACE/memory/$YESTERDAY.md"; do
  if [[ -f "$memfile" ]]; then
    CONTEXT+="## Recent Memory: $(basename "$memfile")"$'\n'"$(cat "$memfile")"$'\n\n'
    echo "  ✅ Loaded $(basename "$memfile")"
  fi
done

# Long-term memory
if [[ -f "$WORKSPACE/MEMORY.md" ]]; then
  CONTEXT+="## Long-Term Memory"$'\n'"$(cat "$WORKSPACE/MEMORY.md")"$'\n\n'
  echo "  ✅ Loaded MEMORY.md"
fi

echo "--- STEP 0 Complete ---"
echo ""

# ═══════════════════════════════════════════════
# STEP 1: GATHER DATA
# ═══════════════════════════════════════════════

echo "--- STEP 1: Gathering Briefing Data ---"

# Weather (example using wttr.in)
WEATHER=$(curl -sf "wttr.in/?format=%C+%t+%p" 2>/dev/null || echo "unavailable")

# Calendar (example — adapt to your calendar system)
# CALENDAR=$(gcal list --today 2>/dev/null || echo "no calendar access")

# Email count (example — adapt to your email system)
# EMAIL_COUNT=$(mail-cli unread-count 2>/dev/null || echo "unknown")

# System health
DISK_USAGE=$(df -h / | tail -1 | awk '{print $5}')
UPTIME=$(uptime | awk -F'( |,)' '{print $5}')

echo "  Weather: $WEATHER"
echo "  Disk: $DISK_USAGE"
echo "  Uptime: $UPTIME"

# ═══════════════════════════════════════════════
# STEP 2: GENERATE BRIEFING (with context)
# ═══════════════════════════════════════════════
#
# This is where you'd invoke your LLM with the context + data.
# The prompt includes STEP 0 context so the agent knows:
# - Who it is (SOUL.md, IDENTITY.md)
# - Who it's helping (USER.md)
# - What happened recently (memory)
# - What it can do (TOOLS.md)

PROMPT="You are generating a morning briefing. Here is your context:

$CONTEXT

Here is today's data:
- Weather: $WEATHER
- Disk usage: $DISK_USAGE
- System uptime: $UPTIME

Generate a concise, personalized morning briefing. Match your personality
from SOUL.md. Reference the human's preferences from USER.md. Include
proactive insights based on recent memory. Keep it short and useful.

IMPORTANT: This is a cron job output that will be delivered as a single
message. Do NOT use tool calls. Do NOT send multiple messages. ONE
consolidated briefing."

# Invoke your agent/LLM here with $PROMPT
# Example (pseudocode):
# agent invoke --prompt "$PROMPT" --output "$WORKSPACE/memory/briefings/$TODAY.md"

echo ""
echo "--- Briefing Generated ---"
```

---

## What STEP 0 Enables in This Example

### Without STEP 0:
```
☀️ Morning Briefing - March 15, 2026

Weather: 62°F, partly cloudy
Disk: 45% used
Uptime: 12 days

Have a good day!
```

### With STEP 0:
```
Morning. Here's what matters:

☁️ 62°F, partly cloudy — no rain, good for your 2 PM outdoor meeting.

📅 Sprint planning at 10 AM (you mentioned wanting to push back the
auth migration — might be a good time). Coffee meeting at 2 PM outdoors,
weather's fine for it.

📧 5 emails, 1 worth reading now: the CI fix from your tech lead.
Rest is newsletters.

🖥️ Systems healthy — 45% disk, 12 days uptime. That API key rotation
you set up last week is due in 3 days.

No action needed from you right now. ☕
```

The difference: personality, awareness, proactive insights, user-appropriate tone. All from reading files before starting work.

---

## Crontab Setup

```bash
# Morning briefing at 8 AM local time
0 8 * * * /path/to/scripts/morning-briefing.sh >> /path/to/logs/briefing.log 2>&1

# Tip: Use the human's timezone from USER.md to set the schedule
# If they're in America/New_York, 8 AM ET = appropriate crontab entry
```

---

## Key Points

1. **STEP 0 is non-negotiable** — without it, cron outputs are generic and useless
2. **Context loading takes milliseconds** — reading 5 markdown files is instant
3. **Memory matters** — loading recent daily notes lets the agent reference ongoing context
4. **Single output** — cron jobs should produce ONE message, never a stream of updates
5. **Log the briefing** — save to `memory/briefings/` for future reference
