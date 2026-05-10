---
name: subagent-dispatch
description: Patterns for delegating work to subagents effectively. Use when spawning coding agents, reviewers, planners, or other specialists.
---

# Subagent Dispatch

Templates and patterns for delegating work to focused subagents instead of running 30+ tool calls inline.

## When to Activate
- Task requires 10+ sequential tool calls
- Work can be parallelized across independent files/modules
- Complex debugging loop (build → test → fix → repeat)
- Code review or verification of completed work
- Research across multiple sources before synthesis

## Core Rules

### 1. Self-Contained Prompts
Workers can't see your conversation. Every spawn prompt must include:
- File paths (absolute, not relative)
- Relevant context (what's broken, what was tried)
- Clear "done" criteria
- Build/test commands to verify

### 2. Synthesize Before Delegating
Understand research findings yourself before writing implementation specs. Never delegate with "based on your findings" — the worker has no findings.

### 3. Parallelize Reads, Serialize Writes
- Research tasks → spawn concurrently
- Implementation on the same files → run sequentially
- Never let two agents write the same file

### 4. Verify For Real
Prove code works (run tests, check output). Don't just confirm files exist.

## Prompt Template

```
## Context
[What exists now — relevant code, architecture, recent changes]

## Task
[Specific deliverable — not vague direction]

## Files
- Read: /path/to/relevant/file.swift
- Modify: /path/to/target/file.swift
- Create: /path/to/new/file.swift

## Constraints
- [Language/framework version requirements]
- [Patterns to follow or avoid]
- [Performance or compatibility requirements]

## Definition of Done
- [ ] Build passes: `xcodebuild build -scheme X 2>&1 | tail -5`
- [ ] Tests pass: `swift test 2>&1 | tail -10`
- [ ] No new warnings introduced
- [ ] [Task-specific acceptance criteria]
```

## Specialist Archetypes

### Architect (Planning)
Use for: design decisions, API design, migration planning, dependency analysis.
```
You are a software architect. Analyze the codebase at /path/to/project and produce:
1. A dependency graph of modules
2. Recommended approach for [goal]
3. Risk assessment and migration steps
Output a markdown document at /path/to/output.md. Do not modify source code.
```

### Builder (Implementation)
Use for: feature implementation, file creation, code generation.
```
You are an implementation specialist. Build [feature] in /path/to/project.
Context: [architecture summary, patterns used]
Files to create/modify: [list]
Definition of done: build passes, tests pass, matches spec in [doc].
```

### Reviewer (Code Review)
Use for: PR review, post-implementation audit, style checks.
```
You are a code reviewer. Review the changes in /path/to/project.
Focus on: correctness, edge cases, naming, test coverage.
Output: structured review with severity (critical/warning/nit) at /path/to/review.md.
Do not modify any files.
```

### Debugger (Fix)
Use for: build errors, test failures, runtime bugs.
```
You are a debugger. The build at /path/to/project is failing.
Error output: [paste errors]
Build command: [exact command]
Fix the errors with minimal changes. Do not refactor or restructure.
Definition of done: `[build command]` exits 0.
```

### Researcher (Investigation)
Use for: API exploration, documentation lookup, feasibility analysis.
```
You are a researcher. Investigate [question/topic].
Search docs, source code, and web resources.
Output: summary with findings, recommendations, and relevant links at /path/to/research.md.
Do not modify any project files.
```

## Continue vs Spawn Decision Table

| Situation | Decision | Why |
|-----------|----------|-----|
| High context overlap with current work | Continue | Agent already has relevant state |
| Low context overlap / new domain | Fresh spawn | Clean slate avoids confusion |
| Fixing a failure from current work | Continue | Failure context is valuable |
| Verifying completed work | Fresh spawn | Independent verification needs fresh eyes |
| Parallel independent tasks | Fresh spawns | No dependencies, maximize throughput |
| Sequential dependent tasks | Continue or chain | Each step needs prior output |

## Anti-Patterns

1. **"Based on your findings"** — Worker has no findings. Synthesize first, then write a concrete spec.
2. **Vague specs** — "Fix the app" tells the worker nothing. Include errors, paths, commands.
3. **Two writers, one file** — Race condition. Serialize writes to the same file.
4. **Inline marathons** — 30+ tool calls inline instead of dispatching. Causes session bloat and burst risk.
5. **Fire and forget** — Spawning without verifying the result. Always check the output.
6. **Over-delegation** — 3-5 tool calls of simple lookups don't need a subagent. Use judgment.
7. **Context dumping** — Pasting entire files into prompts instead of giving paths. Workers can read files.
