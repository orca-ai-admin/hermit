# Multi-Agent Coordination

Patterns for delegating work to subagents effectively. These patterns emerge from running dozens of multi-agent workflows and observing what makes them succeed or fail catastrophically.

## Core Principles

### 1. Self-Contained Prompts

Workers can't see your conversation. They wake up with nothing — no chat history, no implied context, no "you know what I mean." Every delegation prompt must be a complete spec.

**Include in every delegation:**
- File paths (absolute, not relative)
- Line numbers or function names for targeted changes
- The current state ("this file has X, it should have Y")
- What "done" looks like — concrete, testable criteria
- Build and test commands to verify the work

**Good:**
```
Fix the authentication timeout in /src/auth/session.ts.

Current behavior: Sessions expire after 5 minutes regardless of activity.
Expected behavior: Sessions expire after 30 minutes of inactivity, resetting on each request.

The timeout is set on line 47: `const SESSION_TTL = 300;`
Change it to use a sliding window pattern. See the existing `refreshSession()` on line 82.

Verify: `npm test -- --grep "session"` should pass. Currently 2 failures in session.test.ts.
Done when: All session tests pass AND `npm run build` succeeds with no errors.
```

**Bad:**
```
Fix the session timeout issue. Users are complaining.
```

### 2. Synthesize Before Delegating

Never delegate understanding. If a researcher found something, read their findings, understand them yourself, then write a clear implementation spec. The coordinator is a synthesizer, not a relay.

**Anti-pattern:** "Based on the researcher's findings, implement the fix."
**Correct pattern:** Read researcher's output → understand the root cause → write a specific implementation spec with file paths, line numbers, and expected changes.

The coordinator must be the smartest person in the room about the overall system. Workers are specialists who execute precise specs.

### 3. Parallelize Reads, Serialize Writes

Research tasks (reading code, checking logs, investigating bugs) can run concurrently — they don't conflict. Implementation tasks on the same files must be sequential — concurrent writes cause merge conflicts or silent overwrites.

```
✅ Parallel (read-only):
  Worker A: "Read /src/auth/ and document all session handling"
  Worker B: "Read /src/api/ and list all endpoints that check auth"
  Worker C: "Read test failures in CI log and categorize by module"

❌ Parallel (conflicting writes):
  Worker A: "Refactor /src/auth/session.ts to use Redis"
  Worker B: "Add rate limiting to /src/auth/session.ts"

✅ Sequential (dependent writes):
  1. Worker A: Refactor session.ts → done
  2. Worker B: Add rate limiting to the refactored session.ts → done
```

### 4. Continue vs. Spawn Fresh

| Situation | Decision | Why |
|---|---|---|
| High context overlap with current work | Continue in same agent | Avoids re-explaining |
| Low context overlap | Spawn fresh | Clean slate is faster |
| Fixing a failure from a previous attempt | Continue | Agent has failure context |
| Verifying someone else's work | Spawn fresh | Independent perspective |
| Session getting long (>30 messages) | Spawn fresh | Context dilution degrades quality |

### 5. Verify For Real

"Prove code works" means run the tests and see green. Not "the file exists." Not "the syntax looks right." Not "I wrote the test." Run the actual verification command and check the output.

```
# Verification is not:
✅ File created: /src/auth/session.ts

# Verification is:
$ npm test -- --grep "session"
  ✓ session expires after 30 minutes of inactivity (45ms)
  ✓ session resets on activity (12ms)
  ✓ session cleanup removes expired sessions (8ms)
  3 passing (65ms)

$ npm run build
  Build completed successfully.
```

---

## Specialist Archetypes

### Architect

Plans structure, makes design decisions, produces specs for builders.

```
You are an Architect agent. Your job is to produce a detailed implementation plan.

CONTEXT:
We need to add WebSocket support to the API server at /src/server/.
The server currently uses Express with REST endpoints defined in /src/server/routes/.
The client is a React app at /src/client/ that currently polls every 5 seconds.

TASK:
1. Read the current server architecture in /src/server/
2. Read the client polling logic in /src/client/hooks/usePolling.ts
3. Produce a plan that covers:
   - Which WebSocket library to use and why
   - Where the WS server attaches (new file? existing server.ts?)
   - Which endpoints convert from polling to push
   - Client-side changes needed
   - Migration path (both polling and WS work during transition)

OUTPUT: Write the plan to /docs/websocket-plan.md
Done when: Plan exists with all 5 sections filled out, no TODOs or placeholders.
```

### Builder

Implements features from detailed specs. Needs precise instructions.

```
You are a Builder agent. Implement the following change.

SPEC:
Add a health check endpoint to /src/server/routes/health.ts

Requirements:
- GET /health returns { status: "ok", uptime: <seconds>, version: <from package.json> }
- Response time must be <10ms (no DB calls)
- Add to route registry in /src/server/routes/index.ts

FILES TO MODIFY:
- Create: /src/server/routes/health.ts
- Modify: /src/server/routes/index.ts (add import and registration)

BUILD: `npm run build`
TEST: `npm test -- --grep "health"` (write test in /src/server/routes/__tests__/health.test.ts)
Done when: Build passes, test passes, `curl localhost:3000/health` returns valid JSON.
```

### Reviewer

Reviews code for correctness, style, and potential issues. Independent perspective.

```
You are a Reviewer agent. Review the changes in the current git diff.

CONTEXT:
A WebSocket implementation was just added. The diff is in `git diff main..feature/websockets`.

REVIEW CRITERIA:
1. Correctness: Does the implementation handle connection drops, reconnection, and cleanup?
2. Security: Are WS connections authenticated? Can unauthorized clients subscribe?
3. Performance: Any memory leaks from uncleaned event listeners or connections?
4. Error handling: What happens when the WS server crashes? Does REST still work?
5. Tests: Are edge cases covered (concurrent connections, message ordering, large payloads)?

OUTPUT: Write review to /tmp/review-websockets.md with:
- PASS/FAIL verdict
- Critical issues (must fix before merge)
- Suggestions (nice to have)
- Questions for the author
```

### Debugger

Finds and fixes specific bugs. Needs reproduction steps.

```
You are a Debugger agent. Fix this failing test.

FAILING TEST: /src/server/__tests__/session.test.ts line 42
ERROR: "Expected session to be null after expiry, got { id: 'abc', expired: true }"

REPRODUCTION:
cd /project && npm test -- --grep "session expiry" 2>&1 | head -30

CONTEXT:
- Session model is in /src/models/session.ts
- Expiry logic was recently changed in commit abc123
- The test expects `null` but gets an expired session object — likely the cleanup isn't running

CONSTRAINTS:
- Fix the implementation, not the test (test expectations are correct)
- Don't change the session model interface

Done when: `npm test -- --grep "session"` passes all tests (currently 2 of 5 failing).
```

### Researcher

Investigates questions, reads code, produces findings. Read-only.

```
You are a Researcher agent. Investigate and report.

QUESTION: Why are API responses slow (>2s) on the /users endpoint?

INVESTIGATE:
1. Read /src/server/routes/users.ts — check for N+1 queries, missing pagination
2. Read /src/models/user.ts — check query patterns, missing indexes
3. Check /src/server/middleware/ — any middleware adding latency?
4. Read recent commits: `git log --oneline -20 -- src/server/routes/users.ts`

OUTPUT: Write findings to /tmp/research-slow-users.md with:
- Root cause (your best assessment)
- Evidence (specific lines, query patterns, timing data)
- Recommended fix (what a Builder agent would need to know)
- Confidence level (high/medium/low)

DO NOT make any changes. Read-only investigation.
```

---

## When to Delegate vs. Do Inline

### Delegate (spawn a subagent)

- **10+ sequential tool calls** — the work is complex enough to warrant isolation
- **Build-test-debug loops** — iterative cycles that could expand unpredictably
- **Implementation from spec** — writing or modifying multiple files
- **Code review** — benefits from independent perspective
- **Any task with "figure out why"** — debugging is inherently unpredictable in scope

### Do Inline (handle yourself)

- **Quick lookups** — `grep`, `cat`, `git log` (3-5 tool calls)
- **Reading files to answer a question** — just read and respond
- **Single-file, single-line fixes** — edit one thing, done
- **Status checks** — is it running? what version? when was it deployed?
- **Gathering context before writing a delegation spec** — understand first, then delegate

### The 10-Call Rule

If you've made 10 tool calls on a task and you're not done, stop and ask: "Should this be a subagent?" The answer is almost always yes. Inline chains beyond 10 calls cause:
- Session bloat (each call adds ~2-5KB to context)
- Burst risk on messaging surfaces (each intermediate output might become a message)
- Worse outcomes (a focused subagent with a clear spec outperforms a long inline chain)

---

## Anti-Patterns

### 1. Vague Specs

```
❌ "Fix the authentication bug"
❌ "Make the app faster"
❌ "Refactor the user module"
```

Every one of these will produce mediocre results. The worker doesn't know which bug, what "faster" means, or what the refactored module should look like. Be specific or don't delegate.

### 2. Missing Build/Test Commands

If the worker can't verify their own work, they'll claim "done" based on vibes. Always include:
- How to build: `npm run build`, `cargo build`, `swift build`
- How to test: `npm test`, `cargo test -- session`, `swift test --filter SessionTests`
- How to verify: `curl localhost:3000/health`, `cat output.json | jq .status`

### 3. Polling for Status

Subagent results are push-based — they auto-announce when complete. Polling wastes cycles and adds noise.

```
❌ Loop:
  check if worker done → not yet → wait → check again → not yet → wait...

✅ Push:
  Spawn worker → do other work or yield → worker result arrives automatically
```

### 4. Delegating Understanding

The coordinator must understand the problem before delegating the fix. Never:

```
❌ "Researcher found X. Based on their findings, implement a fix."
```

Instead:

```
✅ Read researcher's findings → understand root cause → write specific fix spec:
   "The /users endpoint is slow because of N+1 queries on line 34 of users.ts.
    Replace the loop with a single JOIN query. Here's the expected SQL..."
```

### 5. Over-Delegating Simple Tasks

Not everything needs a subagent. If you can do it in 3 tool calls, just do it. Spawning a subagent has overhead — prompt construction, context setup, result parsing. For quick tasks, inline is faster and cleaner.

### 6. Under-Specifying "Done"

```
❌ "Done when it works"
✅ "Done when: all tests pass, build succeeds, /health returns 200 with valid JSON,
    and no TypeScript errors in `npx tsc --noEmit`"
```

The more concrete the "done" criteria, the less back-and-forth. Workers should be able to verify completion themselves without asking the coordinator.
