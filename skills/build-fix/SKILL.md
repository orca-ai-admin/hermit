---
name: build-fix
description: Fix build errors with minimal changes. No refactoring, no architecture changes — just get the build green.
---

# Build Error Fix

Get the build passing with minimal changes. No refactoring, no improvements — just fix the error.

## When to Activate
- Build fails after code changes
- Compiler errors (type mismatches, missing imports, missing conformances)
- Subagent reporting build failure

## Workflow

### 1. Collect All Errors
Run the build and capture error output. For Xcode/Swift:
```bash
xcodebuild build -scheme "$SCHEME" -destination 'generic/platform=iOS' 2>&1 | grep -E "error:" | head -30
```

### 2. Categorize
Common error types and fixes:
| Error Type | Common Fix |
|-----------|------------|
| Cannot find type/symbol | Add import or check spelling |
| Type mismatch | Add conversion or fix type |
| Missing argument | Add missing parameter |
| Ambiguous reference | Add explicit type annotation |
| Unused result | Add `_ =` or `@discardableResult` |
| Missing conformance | Add required protocol methods |

### 3. Fix Strategy
- Read the error message — understand expected vs actual
- Make the smallest possible change
- Re-run build after each fix
- Iterate until build passes

### 4. Verify
```bash
# Must see: BUILD SUCCEEDED
xcodebuild clean build -scheme "$SCHEME" 2>&1 | tail -5
```

## Rules
- DO: Add type annotations, fix imports, add conformances, add nil checks
- DON'T: Refactor, rename, restructure, add features, change architecture
- Success = build exits 0, minimal lines changed
