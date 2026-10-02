---
description: Bump the SceneView version everywhere, from the single source of truth.
---

# /version-bump — Coordinated version update across all platforms

**Usage:** `/version-bump 3.6.0` or just `/version-bump` (will ask for version)

---

## The one thing to know

`gradle.properties` at the repo root is the source of truth. Everything else is
derived, and `.claude/scripts/sync-versions.sh --fix` derives it — Android modules,
npm packages and their lockfiles, Flutter pubspec + podspec + build.gradle, the
Swift Package `from:` clauses, `llms.txt`, `README.md`, `CLAUDE.md`, every
versioned page under `docs/docs/`, the website, the demo apps, and the AI-assistant
prompt surfaces (`.cursorrules`, `copilot-instructions.md`, `agents/*/SKILL.md`).

Do not hand-edit that list. This command used to carry a prose copy of it, and the
copy was 29 entries against the script's 55-plus: a contributor who followed it
shipped a release with `docs/docs/faq.md`, both iOS codelabs, `Package.swift` and
`.cursorrules` still on the old version. The script is the list.

## Steps

### 1. Read the current version

```bash
grep '^VERSION_NAME=' gradle.properties | cut -d= -f2
```

### 2. Ask for the new version (if not given as an argument)

### 3. Set it at the source, then propagate

```bash
sed -i '' "s/^VERSION_NAME=.*/VERSION_NAME=X.Y.Z/" gradle.properties
bash .claude/scripts/sync-versions.sh --fix
```

### 4. Verify — the same script, without `--fix`

```bash
bash .claude/scripts/sync-versions.sh
```

Exit 0 means every location it knows about is aligned. Anything it still reports is
a location it checks but cannot repair; fix those by hand and say which, so the
missing `--fix` handler can be added.

## The two things the script deliberately leaves alone

- **`mcp/package.json`** — the MCP server has its own release cycle and is published
  to npm independently. Bump it only when you are releasing the MCP server.
- **`sceneview.github.io`** — a separate repository. `website-static/` in this repo
  is swept; the deployed copy is not. Update it there, or let `docs.yml` redeploy.

### 5. Commit

```bash
git add -A
git commit -m "chore: bump version to X.Y.Z"
```
