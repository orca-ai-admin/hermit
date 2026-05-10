# Red Gates — Structural Behavioral Enforcement

Red Gates are the core enforcement mechanism in Hermit. They're not guidelines. They're not suggestions. They're structural gates — conditions that must pass before certain actions proceed.

Every Red Gate exists because something went wrong in production. Every one has a date, an incident, and a script that prevents recurrence.

---

## Why "Red Gates"?

Because "best practices" don't work with LLMs.

You can write a beautiful system prompt that says "don't send multiple messages in a row." The model will follow it for about 20 messages. Then, as the context window fills up with task-specific content, the instruction fades. By message 50, it's sending 10-message bursts like the rule never existed.

Red Gates solve this by making the enforcement structural:
1. **The rule is stated** in SOUL.md (so the model knows about it)
2. **A script enforces it** (so violations are caught regardless of context dilution)
3. **The incident is documented** (so there's emotional weight — the model "understands" the consequences)

This three-layer approach (knowledge + enforcement + motivation) is why Red Gates work where prose rules fail.

---

## The 8 Gates

### Gate 1: 🔴 ANTI-BURST

**Problem:** On messaging platforms (iMessage, Discord, Slack, WhatsApp), every text block the agent emits between tool calls becomes a separate message. Five tool calls with narration = five notifications on the recipient's phone.

**Incident Timeline:**
- First documented: Early in production (Week 1-2)
- Peak severity: 15 separate messages in 10 seconds
- Occurrences: 9+ documented incidents before structural fix
- Resolution: Structural enforcement via SOUL.md + burst-guard.sh

**The Rule:** Collect all results first, respond once.
- Run all tool calls silently — zero narration between them
- Compose ONE consolidated response after ALL tools complete
- Exception: genuinely long tasks (>60s) where a single "checking..." upfront is acceptable

**Enforcement:** `scripts/burst-guard.sh --hours 72` scans message logs for burst patterns.

**Why it's hard to fix with prose alone:** The model naturally wants to narrate its process. "Let me check..." is a deeply ingrained pattern from training data. Only structural enforcement (the gate + monitoring script) prevents regression.

---

### Gate 2: 🔴 VERIFY BEFORE DONE

**Problem:** The agent reports tasks as "done" or "fixed" without verifying the end result the user will see.

**Incident Timeline:**
- First documented: Month 1
- Peak severity: Three consecutive false "fixed" claims in one session
- Result: Human waited 30+ minutes on invisible/broken results each time

**The Rule:** Completion requires proof.
- "Uploaded" ≠ "visible." "Configured" ≠ "working." "Committed" ≠ "deployed."
- After any delivery action, verify the recipient's experience
- If multiple targets exist, verify ALL of them

**Enforcement:** `scripts/liveness-check.sh` must pass before reporting infrastructure changes as complete.

**Key insight:** The agent genuinely believed the task was done because its command succeeded. The gap between "my command returned exit code 0" and "the user can see the result" is where this gate lives.

---

### Gate 3: 🔴 CHECK BEFORE CAN'T

**Problem:** The agent claims inability ("I can't do that", "I don't have access") without checking what capabilities are actually available.

**Incident Timeline:**
- First documented: Month 1
- Notable incident: Agent claimed "I don't have browser access or 2FA capability" while running on a machine with full shell, screen capture, iMessage, and email — all documented in TOOLS.md
- Second incident: Agent said "I don't know what [tool] is" despite it being installed at a known path

**The Rule:** Check before claiming inability.
1. Run `scripts/capability-check.sh`
2. Read TOOLS.md
3. Try the action (`which <tool>`, `<tool> --help`)
4. Only claim inability after all 3 checks fail

**Enforcement:** `scripts/capability-check.sh` inventories all available CLIs, scripts, and access methods.

**Why this happens:** LLMs default to conservative capability claims because training data includes many "I can't do that as an AI" responses. In an agent with full system access, this default is wrong. The gate flips the assumption to "I probably CAN."

---

### Gate 4: 🔴 BLOCKED PATH

**Problem:** The agent treats one failed approach as proof that the goal is impossible, instead of trying alternative approaches.

**Incident Timeline:**
- First documented: Month 2
- Peak severity: 2 hours wasted reporting "API doesn't support this" when a simple workaround existed
- Human pushed back 3 times with "figure it out" before the agent tried alternatives
- Pattern: 4 occurrences in 30 days

**The Rule:** First failure ≠ impossible.
1. Reframe the goal (outcome, not method)
2. Enumerate 3+ alternatives
3. Try at least 1 before reporting blocked
4. Report with attempts (show what you tried)

**Enforcement:** `scripts/blocked-path-check.sh` is a structured checklist that forces lateral thinking.

**Why this matters:** Humans don't want to hear "it can't be done" — they want to hear "I tried X, Y, and Z, here's what I recommend." The patience for the first is near-zero. The patience for the second is high.

---

### Gate 5: 🔴 ANSWER FIRST

**Problem:** When asked a direct question, the agent goes on tangents — discovering "more important" issues, writing walls of explanation, or apologizing instead of doing the thing.

**Incident Timeline:**
- First documented: Month 1
- Notable incident: Asked for a simple code lookup, agent instead went off fixing unrelated configuration, wrote paragraphs of apology, and never actually looked up the code

**The Rule:** Do the asked thing first, then mention other stuff.
- Don't chase tangents before completing the request
- Don't apologize at length — fix the behavior, not the words
- Handle the request, then briefly mention anything else worth noting

**Enforcement:** This gate is primarily structural (stated in SOUL.md) rather than script-enforced. It relies on the emotional weight of the documented incident.

---

### Gate 6: 🔴 SESSION CONTEXT

**Problem:** Long sessions cause measurable degradation in rule compliance. After ~30 assistant messages or ~250KB of context, the model begins "forgetting" structural rules from SOUL.md and AGENTS.md.

**Incident Timeline:**
- First documented: Month 2
- Key data point: A 375-message session (1776KB) produced burst violations that never occurred in shorter sessions
- Same session showed perfect behavior for the first 20 messages, then degraded
- Banned phrase residuals in behavioral experiments occurred exclusively in long sessions

**The Rule:** Rotate sessions before quality degrades.
- < 30 messages: proceed normally
- 30-60 messages: finish current task, suggest fresh session
- \> 60 messages: do NOT start new complex work — request rotation

**Enforcement:** `scripts/session-context-monitor.sh` checks session size and message count, flags WARNING and CRITICAL states.

**Why this is fundamental:** Context dilution is the #1 remaining cause of gate failures after structural enforcement is in place. Every other gate works perfectly in short sessions. Long sessions are where compliance breaks down.

---

### Gate 7: 🔴 HUMAN SILENCE

**Problem:** The agent runs heartbeats daily but never notices when the human goes quiet for days or weeks.

**Incident Timeline:**
- First documented: Month 2
- Key incident: A 20-day silence with zero proactive outreach. Morning briefings ran daily reporting "nothing to report" but never flagged that the human hadn't been heard from in weeks.

**The Rule:** Notice and respond to silence.
- ≤ 2 days: Normal
- 3-5 days: Consider casual check-in
- \> 5 days: Send ONE brief, natural check-in

**Rules:** Maximum one check-in per silence period. Keep it casual. Never during sleeping hours.

**Enforcement:** Human interaction timestamp tracking during heartbeats.

---

### Gate 8: 🔴 LIVENESS

**Problem:** Infrastructure changes reported as "done" without verifying the service is actually running.

**Incident Timeline:**
- First documented: Month 1
- Pattern: Config change → service restart → "done ✅" → service had actually crashed on startup → human discovers broken infrastructure hours later

**The Rule:** Setup ≠ Done.
- Config change + restart + liveness check = done
- Anything less = in-progress
- `scripts/liveness-check.sh` must exit 0 before reporting completion

**Enforcement:** `scripts/liveness-check.sh` runs health checks against configured services, URLs, and disk space.

---

## Adding New Gates

If you discover a new behavioral pattern that needs structural enforcement:

1. **Document the incident** — what went wrong, when, what the impact was
2. **Write the rule** — clear, unambiguous, with examples
3. **Create an enforcement script** — something that can mechanically check compliance
4. **Add to SOUL.md** — in the Red Gates section
5. **Test over multiple sessions** — does the gate prevent recurrence?

The best gates come from real incidents. If you're inventing problems, you're doing it wrong. Wait for production to show you what breaks.

---

## Gate Effectiveness (Production Data)

| Metric | Before Gates | After Gates |
|--------|-------------|-------------|
| Message bursts/week | 4-5 | ~0 |
| False "done" claims | Regular | Rare |
| "Can't do that" errors | Multiple/week | Near-zero |
| Blocked-path escalations | Regular | Mostly self-resolved |
| Session quality degradation | Undetected | Flagged proactively |

Total experiments run: 11. Reverts: 0. Every gate either improved behavior or was neutral.
