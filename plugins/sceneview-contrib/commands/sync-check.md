---
description: Verify SceneView repo synchronization — versions across 30+ files and published artifacts.
---

# /sync-check — Verify SceneView repo synchronization

Run this **before every PR**, at the **end of every session**, and whenever the user asks "where are we" or "is everything ok".

**CRITICAL RULE**: Never tell the user "everything is synced" or "we're good" without running ALL checks below first. Local file versions mean NOTHING if the packages aren't published.

---

## 1. Published packages vs local (MOST CRITICAL)

```
/publish-check
```

Local file versions mean nothing if the packages aren't published. `/publish-check`
queries Maven Central, both npm packages, the git tags and the live site, and prints
the published-vs-local table. This section used to carry its own copy of those same
curl commands; two copies of one check drift, and the one you didn't update is the
one you read.

**This check is a hard blocker. Do NOT skip it.**

## 2. Local version alignment (run the script)

```bash
bash .claude/scripts/sync-versions.sh
```

Exit 0 means every location it knows about is aligned. The script is the list of
locations — this section used to enumerate 22 of them in prose, which was both
incomplete (the script sweeps 55-plus, including `.cursorrules`, `Package.swift`,
`docs/docs/faq.md` and the iOS codelabs) and free to drift, since nothing checks a
comment against the code it describes.

Report any mismatches with: file, current value, expected value.

## 3. Release workflow health

```bash
gh run list --workflow=release.yml --limit 5
```

- Did the last release succeed?
- If it failed, what job failed? (Maven Central, npm, Dokka, GitHub Release)
- Is there a pending tag that wasn't released?

## 4. MCP dist freshness

Compare version strings between `mcp/src/index.ts` and `mcp/dist/index.js`.
If versions differ, run `cd mcp && npm run prepare` and report what changed.

## 5. llms.txt vs Swift source

For each Swift file in `SceneViewSwift/Sources/SceneViewSwift/`:
- Check that the node/struct is documented in the iOS section of `llms.txt`
- Verify the documented signature matches the actual public API

Report any undocumented nodes or signature mismatches.

## 6. llms.txt vs Kotlin source

Check if any new `@Composable` functions or public node classes were added since the last tag:
```bash
LAST_TAG=$(git tag -l 'v*' | sort -V | tail -1)
git diff $LAST_TAG..HEAD -- sceneview/src/ arsceneview/src/ | grep "^+.*fun \|^+.*@Composable\|^+.*class.*Node"
```
If new APIs exist, flag them as needing llms.txt documentation.

## 7. Cross-platform API parity

```bash
bash .claude/scripts/cross-platform-check.sh
```

Report which node types exist on Android but not iOS/Web, and vice versa.

## 8. Docs site deployment

- Check if docs workflow succeeded: `gh run list --workflow=docs.yml --limit 3`
- Is the site accessible? `curl -s -o /dev/null -w "%{http_code}" https://sceneview.github.io/`
- Do the versions on the live site match the current version?

## 9. Build artifacts check

- Are there any tracked build artifacts? `git ls-files -- '*.o' '*.pcm' '*.swiftmodule' '*.class' 'build.db'`
- Are `SceneViewSwift/.build/`, `docs/.cache/`, `docs/site/` in `.gitignore`?

## 10. Stale branches

```bash
git branch -a --no-merged main
```
Flag any branches older than 7 days that haven't been merged.

## 11. Stale worktrees

```bash
ls -la .claude/worktrees/ 2>/dev/null | wc -l
```
If more than 5 worktrees, suggest cleanup.

## 12. Summary

Print a table:

| Check | Status | Details |
|---|---|---|
| Maven Central published | OK/FAIL | published: X.Y.Z, local: X.Y.Z |
| npm sceneview-mcp published | OK/FAIL | published: X.Y.Z, local: X.Y.Z |
| npm sceneview-web published | OK/FAIL | published: X.Y.Z, local: X.Y.Z |
| SPM tag exists | OK/FAIL | latest tag: vX.Y.Z |
| Release workflow | OK/FAIL | last run: success/failure |
| Local versions aligned (30+ files) | OK/FAIL | ... |
| Module gradle.properties | OK/FAIL | ... |
| Flutter pubspec+podspec+build.gradle | OK/FAIL | ... |
| React Native package.json | OK/FAIL | ... |
| Website version | OK/FAIL | ... |
| MCP dist fresh | OK/FAIL | ... |
| llms.txt iOS | OK/FAIL | ... |
| llms.txt Android | OK/FAIL | ... |
| Docs site deployed | OK/FAIL | ... |
| No build artifacts | OK/FAIL | ... |
| No stale branches | OK/FAIL | ... |

**If ANY check fails, do NOT tell the user "everything is good". List every failure clearly and propose fixes.**
