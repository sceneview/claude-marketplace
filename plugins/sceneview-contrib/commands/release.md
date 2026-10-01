---
description: Full SceneView release workflow — version bump, changelog, tag, multi-platform publish.
---

# /release — SceneView release workflow

Guided workflow to bump version, update all references, and prepare a release across ALL platforms.

Ask the user: "What version are we releasing? (current: check root gradle.properties)"

---

## Step 1: Bump the version

```
/version-bump X.Y.Z
```

That command sets the root `gradle.properties` and lets `sync-versions.sh --fix`
derive every other location. This step used to repeat the file list inline as a
"if not using /version-bump" fallback; the two copies had already drifted apart
(the fallback was missing `docs/docs/migration.md`, the AR Compose codelab,
`SceneViewSwift/README.md` and `samples/flutter-demo/pubspec.yaml`), so following
it shipped a partially-bumped release. There is one list now, and it lives in the
script.

## Step 2: Update CHANGELOG.md

Add a new section at the top:
```markdown
## X.Y.Z — YYYY-MM-DD

### New
- ...

### Improved
- ...

### Fixed
- ...
```

Pull from recent git log: `git log <last-tag>..HEAD --oneline`

## Step 3: Rebuild MCP

```bash
cd mcp && npm run prepare && npm test
```

Verify dist/ files are updated and tests pass.

## Step 4: Verify with sync-versions.sh

```bash
bash .claude/scripts/sync-versions.sh
```

ALL checks must pass. If any mismatch, fix before proceeding.

## Step 5: Run quality gate

```bash
bash .claude/scripts/quality-gate.sh --quick
```

## Step 6: Commit and tag

```bash
git add -A
git commit -m "chore: release X.Y.Z"
git tag vX.Y.Z
```

## Step 7: Push

Ask the user: "Push to main and trigger release workflow?"

If yes:
```bash
git push origin main --tags
```

This triggers:
- **release.yml**: Maven Central publish, npm MCP publish, npm sceneview-web publish, GitHub Release
- **play-store.yml**: Android demo AAB build and Play Store upload
- **app-store.yml**: iOS demo TestFlight upload (if Apple cert is configured)
- **docs.yml**: Website + docs rebuild and deploy

## Step 8: Verify published artifacts

Wait 5-10 minutes, then run `/publish-check` to verify all artifacts are live:
- Maven Central: sceneview, arsceneview, sceneview-core
- npm: sceneview-mcp, @sceneview/sceneview-web
- GitHub Release with APKs attached
- SPM tag available

## Step 9: Post-release

Update the deployed website (`sceneview.github.io`) if it carries version
references. Discord is notified by webhook — nothing to do.

---

## Artifact publishing matrix

| Artifact | Where | How | Trigger |
|---|---|---|---|
| sceneview | Maven Central | release.yml | git tag v* |
| arsceneview | Maven Central | release.yml | git tag v* |
| sceneview-core | Maven Central | release.yml | git tag v* |
| sceneview-mcp | npm | release.yml | git tag v* |
| sceneview-web | npm | release.yml | git tag v* |
| SceneViewSwift | SPM (git tag) | git tag | Manual |
| GitHub Release | GitHub | release.yml | git tag v* |
| Demo APKs | GitHub Release | build-apks.yml | git tag v* |
| Play Store | Google Play | play-store.yml | push to main |
| TestFlight | App Store | app-store.yml | push to main (needs cert) |
| Website | GitHub Pages | docs.yml | push to main |

**Important:** Never skip the sync-versions check. Version drift is the #1 source of bugs in this repo.
