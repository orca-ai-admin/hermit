# HEARTBEAT.md — Proactive Check System

Heartbeats are periodic check-ins where you do useful work without being asked.

## Schedule

Run heartbeats 2-4 times per day, spaced at least 3 hours apart. Track state in `memory/heartbeat-state.json`.

**Quiet hours:** No heartbeats between 23:00 and 08:00 (user's timezone).

---

## Heartbeat Checklist

Each heartbeat, rotate through these checks. Don't run all of them every time — pick 2-4 based on what's most relevant.

### Communication Checks
- [ ] **Email** — Any new important emails? Triage and flag urgent ones.
- [ ] **Messages** — Unread messages that need attention?
- [ ] **Mentions** — Tagged anywhere? (GitHub, Discord, Slack, etc.)

### Calendar & Time
- [ ] **Upcoming events** — Anything in the next 24-48 hours?
- [ ] **Reminders** — Any pending reminders or deadlines approaching?

### Infrastructure
- [ ] **Service health** — Run `scripts/liveness-check.sh`
- [ ] **Disk space** — Getting low?
- [ ] **Background jobs** — Any cron jobs failing silently?

### Human Awareness
- [ ] **Silence check** — How long since last human interaction?
- [ ] **Context check** — Anything the human should know about?

### Proactive Work
- [ ] **Memory consolidation** — Time for a dream cycle? (every 3-4 days)
- [ ] **Documentation** — Any TOOLS.md or MEMORY.md updates needed?
- [ ] **Cleanup** — Old temp files, stale branches, expired sessions?

---

## Heartbeat State

Track what you checked and when in `memory/heartbeat-state.json`:

```json
{
  "last_heartbeat": "2026-03-15T14:30:00Z",
  "last_email_check": "2026-03-15T14:30:00Z",
  "last_calendar_check": "2026-03-15T10:00:00Z",
  "last_dream_cycle": "2026-03-13T03:00:00Z",
  "last_human_interaction": "2026-03-15T12:45:00Z",
  "checks_today": 2
}
```

---

## When to Reach Out

**Do reach out when:**
- Important email that needs timely action
- Calendar event less than 2 hours away
- Infrastructure issue detected
- Extended human silence (> 5 days)

**Don't reach out when:**
- It's quiet hours
- Nothing has changed since last check
- You checked less than 30 minutes ago
- The information can wait until the human initiates

---

## Proactive Work (No Permission Needed)

During heartbeats, you can do background work without asking:
- Organize and consolidate memory
- Update documentation
- Check and fix infrastructure issues
- Run dream cycles
- Clean up workspace

Goal: helpful without annoying. Background work > status reports.
