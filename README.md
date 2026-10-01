# SceneView Claude Code marketplace

A [Claude Code](https://code.claude.com/docs/en/plugins) plugin marketplace for
[SceneView](https://github.com/sceneview/sceneview), the open-source 3D & AR SDK for Android
(Jetpack Compose), iOS / macOS / visionOS (SwiftUI) and the web.

SceneView supports every AI assistant at the same level; this repository is the Claude Code
packaging. The equivalent setup for Codex, Gemini CLI, Cursor, Copilot and others is on
[AI-assisted development](https://sceneview.github.io/docs/ai-development/).

## Install

```
/plugin marketplace add sceneview/claude-marketplace
/plugin install sceneview@sceneview
```

## Plugins

| Plugin | For | Contents |
|---|---|---|
| [`sceneview`](plugins/sceneview) | Anyone building an app with SceneView | The three SceneView skills (`sceneview`, `sceneview-ios`, `sceneview-web`) and the [`sceneview-mcp`](https://www.npmjs.com/package/sceneview-mcp) server |
| [`sceneview-contrib`](plugins/sceneview-contrib) | Contributors to the SDK repository | Maintainer commands (review, test, version bump, release) and cross-platform parity reminder hooks |

## How this marketplace is structured

The MCP server is not vendored: the plugin's `.mcp.json` runs the npm package through `npx`.
The skills are copies of [`agents/`](https://github.com/sceneview/sceneview/tree/main/agents) in
the SDK repository, the same source the Codex plugin reads.

## Keeping it in sync

The `sceneview` plugin version tracks the `sceneview-mcp` npm version, and its skills track
`agents/` on the SDK's `main` branch:

```bash
bash scripts/sync-plugin-versions.sh         # report
bash scripts/sync-plugin-versions.sh --fix   # bump the versions and refresh the skill copies
```

CI runs the report on every push and weekly.

## Validate

```bash
claude plugin validate .
claude plugin validate plugins/sceneview
claude plugin validate plugins/sceneview-contrib
```

## License

Apache-2.0 (see [`LICENSE`](LICENSE)). The `sceneview-mcp` npm package is MIT.
