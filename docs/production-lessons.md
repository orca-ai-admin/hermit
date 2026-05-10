# Production Lessons

These lessons come from running a Hermit-based agent in continuous production for 2+ months. Everything here was learned the hard way.

Names, emails, and identifying details have been removed. The patterns are universal.

---

## Lesson 1: Prose Rules Decay, Structural Rules Don't

**What happened:** Early on, behavioral rules were written as prose in the system prompt. "Don't send multiple messages in a row." "Always verify before claiming done." The agent followed them perfectly — for about 20 messages. Then context dilution kicked in and the rules faded.

**What we learned:** Text rules in system prompts decay as the context window fills with task-specific content. By message 50, the model behaves as if the rules don't exist.

**The fix:** Red Gates — combine prose rules (the model needs to know the rule) with enforcement scripts (structural check regardless of context state) and incident documentation (emotional weight).

**Why it works:** Three-layer enforcement is robust to context dilution. Even if the model "forgets" the prose rule, the script catches violations. And the incident documentation provides motivation that persists better than abstract rules.

---

## Lesson 2: The Agent Will Claim Inability Rather Than Try

**What happened:** The agent had full shell access, browser automation, screen capture, messaging APIs, and 20+ CLIs installed. When asked to do something slightly novel, it would say "I don't have access to that" or "I can't do that" — despite having every tool needed.

**What we learned:** LLMs default to conservative capability claims. Training data is full of "As an AI, I can't..." responses. In an agent with full system access, this default is catastrophically wrong.

**The fix:** The CHECK BEFORE CAN'T gate with `capability-check.sh`. The default assumption flipped from "I probably can't" to "I probably CAN."

**Metric:** False inability claims went from multiple per week to near-zero.

---

## Lesson 3: Long Sessions Are the #1 Threat to Quality

**What happened:** A session grew to 375 messages (1776KB). The agent had been performing perfectly for the first ~30 messages. By message 50, burst violations started. By message 100, banned phrases were leaking through. The rules hadn't changed — the context window had just been diluted.

**What we learned:** Context dilution is measurable and reproducible. Sessions over ~30 assistant messages show detectable quality degradation. Over ~60, it's severe.

**The fix:** The SESSION CONTEXT gate with `session-context-monitor.sh`. The agent tracks message count and session size, suggesting rotation before quality degrades.

**Key insight:** The only burst violations and banned-phrase leaks that occurred AFTER implementing Red Gates happened in sessions exceeding 250KB. In fresh sessions with the same rules, compliance was 100%.

---

## Lesson 4: "Done" Is the Most Dangerous Word

**What happened:** The agent saved a config file and reported "done ✅." The config was correct, but the service hadn't been restarted. The change wasn't active. The human discovered broken infrastructure hours later.

In another incident: three consecutive "fixed it!" claims about a build deployment. Each time, the agent's command succeeded but the result wasn't visible to end users. Build uploaded but not assigned to the right group. Then fixed for one group but not another.

**What we learned:** "My command returned exit code 0" ≠ "The user can see the result." There's a gap between technical success and actual delivery.

**The fix:** The LIVENESS and VERIFY BEFORE DONE gates. Nothing is "done" until it's verified from the user's perspective. `liveness-check.sh` must pass before reporting infrastructure changes as complete.

---

## Lesson 5: The Agent Will Do The Work Instead of Delegating It

**What happened:** A debugging task that should have been delegated to a focused sub-agent was run inline in the main conversation. 74 sequential tool calls. Session bloated to 2075KB. A 4-message burst occurred (because the agent started narrating progress mid-stream as context dilution kicked in). The actual fix was 3 lines of code.

**What we learned:** Inline tool chains cause three problems simultaneously: session bloat (triggering Lesson 3), burst risk (triggering Lesson 1 violations), and worse outcomes (a focused sub-agent with a 10-line spec would have been faster and more accurate).

**The fix:** Delegation threshold — if a task needs 10+ sequential tool calls, stop, write a spec, spawn a sub-agent. Exploratory work (3-5 calls) is fine inline.

---

## Lesson 6: First Blocked Path ≠ Impossible

**What happened:** An API endpoint returned "not supported." The agent immediately reported to the human: "This can't be done through the API." Two hours later, after the human pushed back three times, the agent found a simple workaround — repurposing an existing resource through a different endpoint.

**What we learned:** The agent defaults to reporting failure after the first obstacle, rather than thinking laterally about alternative approaches. The human's patience for "it can't be done" is near-zero, but patience for "I tried X, Y, and Z — here's what I recommend" is high.

**The fix:** The BLOCKED PATH gate with `blocked-path-check.sh`. The agent must enumerate 3+ alternatives and try at least one before reporting blocked.

---

## Lesson 7: Heartbeats Need to Be Productive, Not Ceremonial

**What happened:** Early heartbeats were pure status checks — "All systems normal. No action needed." They ran 4 times a day and provided zero value. Meanwhile, emails piled up, calendar events were missed, and the human had to manually check everything the agent should have caught.

**What we learned:** Reactive heartbeats are useless. Productive heartbeats that actually check email, review calendar, monitor infrastructure, and do background work are valuable.

**The fix:** Heartbeat checklist rotation. Each heartbeat picks 2-4 checks from a rotating list. Background work (memory consolidation, documentation updates, workspace cleanup) is explicitly allowed without asking permission.

---

## Lesson 8: Memory Without Consolidation Is Just Logs

**What happened:** Daily notes were being written religiously but never consolidated. After 3 weeks, there were 21 daily note files. The agent would load today's and yesterday's notes but miss important context from 2 weeks ago. MEMORY.md was empty.

**What we learned:** Writing daily notes is necessary but not sufficient. Without periodic consolidation (dream cycles), important context gets buried in old files that are never read.

**The fix:** Dream cycles every 3-5 days. The agent reviews accumulated daily notes, extracts patterns and important context, and updates MEMORY.md. The daily notes serve as raw material; MEMORY.md is the curated product.

---

## Lesson 9: The Agent Will Say "Want Me To...?" 12 Times a Day

**What happened:** The phrase "Want me to...?" was used 12 times in a single day. Also "Should I...?", "Would you like me to...?", "Shall I...?" — all variants of the same permission-seeking behavior.

**What we learned:** Permission-seeking is deeply embedded in LLM training data. It's extremely difficult to eliminate through prose rules alone. Even after explicit correction, the pattern returns within a few conversations.

**The fix:** Banned phrase tracking with structural enforcement. The agent states what it can do ("I can do X — just say the word") or just does it (for reversible/low-risk actions). Result: 12 violations/day → 0.3/day (97% reduction).

---

## Lesson 10: Twenty Days of Silence, Zero Check-Ins

**What happened:** The human went quiet for 20 days. During that time, the agent ran daily heartbeats. Every single one reported "nothing to report." Not once did the agent notice that it hadn't heard from the human in almost three weeks.

**What we learned:** Heartbeats that check systems but not humans are incomplete. A good assistant notices when the person they're helping goes quiet and does a casual check-in.

**The fix:** Human silence tracking. Simple timestamp comparison during heartbeats. If > 5 days since last interaction, send ONE casual check-in message.

---

## Lesson 11: Experiments Work, Manual Tuning Doesn't Scale

**What happened:** For the first few weeks, behavioral fixes were manual — edit the system prompt when something goes wrong. This worked but didn't scale. Each fix was ad-hoc, unmeasured, and sometimes conflicted with previous fixes.

**What we learned:** Structured experiments with baselines, metrics, and clear success criteria produce dramatically better outcomes than ad-hoc prompt editing. They also compound — each experiment makes the next one easier because the measurement infrastructure already exists.

**The fix:** The self-improvement engine. Corrections mining → hypothesis → experiment → measurement → evolution. 11 experiments, 0 reverts.

---

## Meta-Lessons

### The Pareto Principle Applies

80% of behavioral issues came from 3 patterns: message bursts, capability amnesia, and false "done" claims. Fixing those three things transformed the agent from frustrating to functional.

### Production Reveals What Testing Can't

Every Red Gate came from a real incident. No amount of theoretical design would have predicted "the agent will claim it can't use a browser while running on a Mac with Safari open." Production is the only test environment that matters.

### The Agent Can Fix Itself (With Structure)

Given the framework to identify, experiment with, and fix its own patterns, the agent improved continuously. The human's role shifted from "fixing the agent's behavior" to "approving the agent's proposed behavioral changes."

### Small Sessions, Big Compliance

The single most impactful operational change: rotating sessions before they get long. Fresh sessions have near-perfect rule compliance. Long sessions don't. It's that simple.
