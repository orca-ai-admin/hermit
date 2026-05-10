# Hermit 🐚 — Launch Posts

---

## 1. X/Twitter Post

**Format: Thread (3 tweets)**

**Tweet 1:**
I told my AI agent "don't send message bursts" in the system prompt.

It worked great. For about 20 minutes.

Then it sent 15 notifications in 10 seconds at 2am.

So I wrote it into the system prompt AGAIN, in bold, with examples.

It lasted maybe an hour this time. 🧵

**Tweet 2:**
After 2 months of this, I stopped asking nicely.

I built shell scripts that COUNT recent messages and BLOCK the action before it happens. Prose rules → structural enforcement.

The result:
- 97% reduction in banned phrase violations
- Message bursts: eliminated
- 12 structured experiments, 0 reverts
- 8 enforcement gates running in production

**Tweet 3:**
I open-sourced the whole framework. It's called Hermit 🐚 (named after the crab — it outgrows its shell).

Markdown files + shell scripts. No proprietary runtime. Works with whatever LLM you're already using.

https://github.com/orca-ai-admin/hermit

---

## 2. Reddit Post (r/LocalLLaMA)

**Title:** I ran an AI agent 24/7 for 2+ months. "Just write a good system prompt" doesn't work. Here's what does.

**Body:**

I've been running an autonomous AI agent in production — real tasks, real integrations, real consequences — continuously for over two months. Not a weekend experiment. A system that manages messages, monitors services, and operates independently around the clock.

Here's what I learned: system prompts decay.

You write "never send multiple messages in rapid succession." It works. Then at message 50 in a long session, the context window fills up, the rule fades, and your phone buzzes 12 times at 3am. So you rewrite the prompt in bold. Add examples. Say "THIS IS CRITICAL." Same result, different day.

The problem isn't the instruction. It's the enforcement mechanism. Prose rules live in the context window, and context windows have finite attention. The longer the session, the less the model "remembers" the rules it loaded at the start.

**Red Gates: structural enforcement**

Hermit uses what I call Red Gates — 8 enforcement checkpoints that use shell scripts, not natural language, to enforce behavior. Instead of "please don't send bursts," there's a script that counts messages sent in the last N seconds and blocks the action if it exceeds a threshold. The model can't "forget" the rule because the rule isn't in its context — it's in the infrastructure.

Examples:
- **Anti-Burst Gate**: counts recent messages, blocks rapid-fire sends
- **Capability Gate**: before the agent says "I can't do that," a script inventories every CLI and tool on the machine — forces it to check before claiming inability
- **Liveness Gate**: "done" means verified running, not "I edited the config file"
- **Session Context Gate**: monitors session length and forces rotation before context dilution causes rule decay

**Self-improvement engine**

Hermit includes a correction-mining system. When I correct the agent, it logs the correction, categorizes it, and periodically runs structured experiments to fix the root cause. 12 experiments so far, 0 reverts. The 97% reduction in banned phrase violations came from one of these experiments — not from me rewriting the prompt for the 50th time.

There's also a memory consolidation system loosely inspired by how sleep consolidation works in neuroscience — periodic "dream cycles" that compress daily logs into long-term memory, prune stale context, and surface patterns.

**What Hermit is NOT**

- Not an agent framework like AutoGPT or CrewAI — no built-in tool use, no orchestration runtime
- Not model-specific — it's markdown files and shell scripts, works with whatever you're running
- Not magic — you still need to observe, correct, and iterate. It just makes the iteration structured instead of ad hoc
- Not a finished product — it's a framework extracted from a production system, shared because the patterns seem broadly useful

**The repo**

https://github.com/orca-ai-admin/hermit

The core insight is dead simple: behavioral rules enforced by shell scripts survive context window decay. Behavioral rules written in prose don't. Everything else in Hermit follows from that.

Curious what patterns others have found for keeping long-running agents on track. What's worked? What hasn't?

— [Aston](https://www.linkedin.com/in/astonlee)

---

## 3. Hacker News (Show HN)

**Title:** Show HN: Hermit – Self-evolving agent framework (markdown + shell scripts)

**Body:**

Telling an LLM "don't send too many messages" works for about 20 minutes. A shell script that counts recent messages and blocks the action works forever.

That's the core idea behind Hermit. I've been running an AI agent autonomously for 2+ months and kept hitting the same problem: behavioral rules written in the system prompt degrade as session context grows. The model complies at message 5 and violates at message 50. Rewriting the prompt doesn't fix it — the failure mode is structural, not instructional.

Hermit enforces behavior through shell scripts instead of prose. Eight "Red Gates" act as checkpoints — the agent literally cannot claim "I can't do that" without a script first inventorying every tool on the machine, cannot report a task "done" without a liveness check passing, cannot send messages without a burst-counter clearing the action.

It also includes a self-improvement loop: corrections get logged, categorized, and periodically turned into structured experiments. 12 experiments run so far, 0 reverted. One experiment alone reduced a specific behavioral violation by 97%.

The whole thing is markdown files and shell scripts. No runtime, no proprietary anything. Named after the hermit crab — it outgrows its shell.

https://github.com/orca-ai-admin/hermit
