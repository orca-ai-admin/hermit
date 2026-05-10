# Messaging Surfaces

How to prevent message bursts on platforms like iMessage, Discord, WhatsApp, and Slack — where every text block between tool calls becomes a separate notification.

## The Problem

When an AI agent runs on a messaging platform, each text response it emits between tool calls is delivered as a **separate message**. This is a platform constraint, not a bug — messaging APIs treat each text submission as an independent message.

The result: if an agent needs 5 tool calls to answer a question and narrates between each one ("Let me check...", "Now looking at...", "Found it!"), the user's phone buzzes **5 times in 10 seconds** with incremental, low-value messages.

This is the single most common complaint from users of AI agents on messaging surfaces. It feels like spam.

```
❌ What the user experiences:

[buzz] "Let me check that for you..."
[buzz] "Looking at the calendar now..."
[buzz] "I see you have 3 events tomorrow..."
[buzz] "Let me also check the weather..."
[buzz] "Tomorrow: 3 meetings, sunny, 72°F. Here's the rundown..."

5 notifications. 4 of them are useless filler. The user wanted ONE answer.
```

## The Rule: Collect First, Respond Once

### 1. Plan Silently

Before starting any tool calls, decide what information you need. Don't announce your plan.

### 2. Run Tools WITHOUT Narration

Execute all tool calls with zero text between them. No "checking...", no "found it...", no "now let me...". Just the tool calls, back to back.

### 3. Compose ONE Response

After all tool calls complete and you have all the information, compose a single consolidated response.

### 4. Deliver That Single Response

The user sees one message with the complete answer. One notification. One buzz.

```
✅ What the user should experience:

[buzz] "Tomorrow: 3 meetings (standup at 9, design review at 11, 1:1 at 3).
        Weather: sunny, 72°F. No conflicts with your gym slot at 7am."

1 notification. Complete answer. Respectful of their attention.
```

## Structural Enforcement

### Zero Text Between Tool Calls

On messaging surfaces, treat any text between tool calls as a bug. The only text the user should see is your final consolidated answer.

**Self-check:** If you're about to write text and you know another tool call is coming, STOP. Delete the text. Run the tool call. Continue silently.

### The 60-Second Exception

For tasks that genuinely take a long time (>60 seconds), ONE upfront acknowledgment is acceptable:

```
✅ "Checking — this might take a minute."
[...tool calls run silently...]
"Here's what I found: ..."
```

That's **one** acknowledgment, not one per tool call. And only when the delay is significant enough that the user might think the agent crashed.

### Recovery Pattern

If you catch yourself mid-burst (you've already sent intermediate text):

1. Stop immediately — don't compound the burst
2. Complete remaining tool calls silently
3. Send the final consolidated answer
4. Don't apologize for the burst in-band (that's another message)

## Detection

### Burst Guard Script

A burst detection script counts assistant messages within sliding time windows. Run it during periodic health checks to catch violations:

```bash
#!/bin/bash
# burst-guard.sh — detect message bursts in session logs
# Counts assistant messages within 10-second windows

HOURS=${1:-72}  # Look back N hours (default 72)
THRESHOLD=${2:-3}  # Burst threshold (default 3 messages in a window)

# Implementation scans session logs for clusters of assistant messages
# with timestamps within 10 seconds of each other.
# Output: session ID, timestamp, message count, and context snippet
# for each detected burst.

echo "Scanning last ${HOURS}h for bursts > ${THRESHOLD} messages in 10s windows..."
# ... scan logic against your session log format ...
```

**Integration:**
- Run during heartbeat checks (2-4x daily)
- Alert when bursts > threshold are detected
- Track burst count over time to measure improvement
- Investigate which sessions and contexts produce bursts

### What Counts as a Burst

- **3+ assistant messages within a 10-second window** = burst
- Single-message responses are fine regardless of length
- Multiple messages spread across minutes (natural conversation) are fine
- The concern is rapid-fire messages that arrive as a wall of notifications

## Platform-Specific Formatting

Different messaging platforms render content differently. What looks great in a terminal can be unreadable in WhatsApp.

### Discord

- **No markdown tables** — Discord renders tables as monospace blocks that look terrible on mobile. Use bullet lists instead.
- **Suppress link embeds** — Wrap URLs in angle brackets to prevent preview cards from cluttering the chat: `<https://example.com>`
- **Code blocks work** — Discord supports ` ``` ` fenced code blocks with syntax highlighting
- **Reactions** — Use emoji reactions to acknowledge messages without sending a new message. One reaction per message max.

```
❌ Discord table (renders as ugly monospace):
| Name | Status | Notes |
|------|--------|-------|
| API  | Up     | v2.1  |

✅ Discord bullet list:
- **API**: Up (v2.1)
- **DB**: Up (healthy)
- **Cache**: Down (investigating)
```

### WhatsApp

- **No markdown headers** — WhatsApp doesn't render `#` headers. Use **bold** or CAPS for emphasis.
- **No markdown tables** — Same as Discord. Bullet lists only.
- **No code blocks** — WhatsApp has basic monospace (backticks) but no fenced blocks. Keep code snippets short.
- **Bold and italic work** — `*bold*` and `_italic_` render correctly.
- **Link previews** — WhatsApp auto-generates previews. No way to suppress them.

```
❌ WhatsApp with headers:
## Status Report
### Services
API is up...

✅ WhatsApp with bold:
*STATUS REPORT*

*Services*
- API: up ✅
- DB: up ✅
```

### iMessage

- **Minimal formatting** — iMessage supports almost no rich text via API. Plain text with emoji works best.
- **Keep messages concise** — Long messages get truncated in notification previews. Lead with the important part.
- **No markdown** — Nothing renders. Write plain text.

### Slack

- **Slack markdown** — Slack has its own markdown variant. `*bold*`, `_italic_`, `` `code` ``, `> quote`.
- **Blocks and attachments** — If your platform supports Slack's Block Kit, use structured messages for rich content.
- **Thread replies** — Use threads to keep conversations organized. Reply in-thread rather than in the main channel.

## Common Mistakes

### 1. Narrating Tool Calls

```
❌ "Let me check your calendar..."
   [reads calendar]
   "I see 3 events. Let me also check the weather..."
   [reads weather]
   "Here's your summary..."

✅ [reads calendar]
   [reads weather]
   "Tomorrow: 3 events, sunny 72°F. Morning clear until standup at 9."
```

### 2. Thinking Out Loud

```
❌ "Hmm, that's interesting. The error suggests a timeout. Let me look at the logs..."
   [reads logs]
   "Found it! The database connection pool is exhausted. Let me check the config..."
   [reads config]
   "The pool size is set to 5, which is too low."

✅ [reads logs]
   [reads config]
   "Database connection pool is exhausted — pool size is 5, which is too low for
    your current load. Recommend increasing to 20 in config/database.yml line 12."
```

### 3. Progress Updates Nobody Asked For

```
❌ "Starting the deploy..."
   "Build complete..."
   "Pushing to staging..."
   "Running health checks..."
   "Deploy complete! ✅"

✅ [runs all deploy steps silently]
   "Deploy complete ✅ — staging is live at https://staging.example.com, health check passed."
```

### 4. Apologizing in a Separate Message

```
❌ [burst of 5 messages]
   "Sorry about the multiple messages!"  ← this is message #6

✅ [burst happens]
   [fix behavior going forward, don't add another message about it]
```
