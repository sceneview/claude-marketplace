---
description: Comprehensive pre-push quality gate — compile, unit tests, bundle build, website JS validation.
---

# /quality-gate — Comprehensive pre-push quality gate

Run this BEFORE every push to ensure nothing is broken across ALL platforms.

---

There is no single gate script (the old `quality-gate.sh` was removed in
sceneview#3244): run the steps below in order and report each one as PASS, WARN
or FAIL.

## Quick mode

For fast checks (git state, version sync, changelog fragments, security, code
quality — sections 1 to 4 and 6, no build/test):
```bash
bash .claude/scripts/sync-versions.sh
bash .claude/scripts/check-changelog-fragments.sh
```

## Full mode (default)

Quick mode, then section 5 (build and tests).

## What it checks

### 1. Git state
- Current branch
- No merge conflicts
- No large files (>10MB) staged

### 2. Version sync (CRITICAL)
- `gradle.properties` (root) vs all modules
- `llms.txt` artifact versions match
- `README.md` install snippets match

### 3. Security (CRITICAL)
- No secrets tracked (`.env`, `credentials.json`, `keystore.jks`, `google-services.json`)
- `local.properties` not in git
- No API keys in staged changes

### 4. Code quality
- No `!!` (force unwrap) in Kotlin — prefer safe calls
- No Filament JNI calls on background threads (THREADING VIOLATION)
- No new TODO/FIXME without corresponding issue

### 5. Build & test (full mode only)
- `./gradlew assembleDebug`
- `./gradlew :sceneview:testDebugUnitTest :arsceneview:testDebugUnitTest`
- `cd mcp && npm test`

### 6. Cross-platform consistency
- If Android APIs changed, check if `llms.txt` was updated
- If new public APIs added, flag for documentation

## After running

If the gate BLOCKS:
1. Fix all FAIL items
2. Re-run the gate
3. Only push when all checks pass

If warnings only:
- Review each warning
- Push if warnings are intentional/expected
