---
name: verification-loop
description: Post-implementation verification checklist. Run after completing features, before claiming "done". Never skip.
---

# Verification Loop

Verify that work is actually done — not just "code written." Run this after every feature, fix, or infrastructure change before reporting completion.

## When to Activate
- After implementing a feature or fix
- Before reporting "done" to the user
- After infrastructure changes (config, deploys, service restarts)
- After subagent completes delegated work
- Before opening a PR

## Phases

### Phase 1: Build Verification
**Required.** No exceptions.

```bash
# Clean build — catches stale artifacts
xcodebuild clean build -scheme "$SCHEME" -destination 'generic/platform=iOS' 2>&1 | tail -20

# Check exit code
echo "Exit: $?"
```

- ✅ PASS: `BUILD SUCCEEDED`, exit 0
- ❌ FAIL: Any `error:` in output or non-zero exit
- ⚠️ WARN: New warnings introduced (compare to baseline if available)

### Phase 2: Test Suite
Run all tests. Report actual counts.

```bash
# Run tests
xcodebuild test -scheme "$SCHEME" -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -30

# Or for Swift packages:
swift test 2>&1 | tail -20
```

- ✅ PASS: All tests pass, zero failures
- ❌ FAIL: Any test failure
- ⚠️ WARN: Tests skipped or test count decreased

Report format: `X passed, Y failed, Z skipped`

### Phase 3: Static Analysis
Check for debug artifacts and code quality issues.

```bash
# Debug artifacts left behind
grep -rn "print(" --include="*.swift" Sources/ | grep -v "// ok-print" | head -10
grep -rn "TODO\|FIXME\|HACK\|XXX" --include="*.swift" Sources/ | head -10

# SwiftLint if available
which swiftlint && swiftlint lint --quiet 2>&1 | tail -20
```

- ✅ PASS: No debug prints, no new TODOs, lint clean
- ⚠️ WARN: New TODOs (acceptable if tracked), minor lint issues
- ❌ FAIL: Debug prints in production code, critical lint violations

### Phase 4: Diff Review
Review what actually changed. Catch unintended modifications.

```bash
# What files changed
git diff --stat HEAD

# Full diff for review
git diff HEAD

# Check for unintended changes
git diff --name-only HEAD | wc -l
```

Questions to answer:
- Are all changed files related to the task?
- Any unintended formatting changes?
- Any files modified that shouldn't be?
- Are new files in the right locations?

- ✅ PASS: All changes intentional and task-related
- ❌ FAIL: Unrelated changes, accidental deletions, wrong files modified

### Phase 5: Delivery Verification
**Required.** Verify the recipient's experience, not just your exit code.

| Delivery Type | How to Verify |
|--------------|---------------|
| TestFlight build | Check build appears in App Store Connect groups |
| Deploy | Hit the endpoint, check the response |
| Email/notification | Verify it arrived at destination |
| Config change | Restart service, verify new behavior |
| PR | Check it's visible on GitHub, CI passes |
| File output | Open/read the output file, verify contents |

**"Uploaded" ≠ "visible." "Configured" ≠ "working." "Committed" ≠ "deployed."**

- ✅ PASS: End user/recipient can see and use the deliverable
- ❌ FAIL: Deliverable not accessible to recipient

### Phase 6: Report

Generate a structured report:

```
## Verification Report

| Phase | Status | Details |
|-------|--------|---------|
| 1. Build | ✅ PASS | BUILD SUCCEEDED, 0 warnings |
| 2. Tests | ✅ PASS | 47 passed, 0 failed, 0 skipped |
| 3. Static | ⚠️ WARN | 2 new TODOs (tracked in #123) |
| 4. Diff | ✅ PASS | 3 files changed, all task-related |
| 5. Delivery | ✅ PASS | Build visible in TestFlight group |

**Overall: ✅ READY** (or ❌ NOT READY)
```

## Rules

1. **Never claim "done" without Phase 1 (Build) + Phase 5 (Delivery).** These are non-negotiable.
2. **Fix failures before reporting.** Don't report "done with issues" — fix the issues first.
3. **Report real numbers.** "Tests pass" is not a count. "47 passed, 0 failed" is.
4. **Check ALL targets.** If delivery has multiple recipients (groups, environments), verify each one.
5. **Re-run after fixes.** If Phase 1 fails and you fix it, re-run ALL phases — fixes can break other things.
6. **Warnings are not failures** but should be noted. New warnings in previously clean code deserve attention.
7. **Skip phases explicitly.** If a phase doesn't apply (e.g., no tests exist), mark it `⏭ SKIPPED — no test suite` rather than omitting it.
