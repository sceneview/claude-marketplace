# SceneView Claude Code marketplace

A [Claude Code](https://www.anthropic.com/claude-code) plugin marketplace for [SceneView](https://github.com/sceneview/sceneview) — the cross-platform 3D & AR SDK for Android (Jetpack Compose), iOS / macOS / visionOS (SwiftUI), and Web (Kotlin/JS).

## Install

```
/plugin marketplace add sceneview/claude-marketplace
/plugin install sceneview@sceneview
```

## Plugin

| Plugin | Wraps | License |
|---|---|---|
| `sceneview` | [`sceneview-mcp`](https://www.npmjs.com/package/sceneview-mcp) — 28 tools, full SceneView API reference, code validator. Ships with 11 contributor commands and cross-platform reminder hooks. | Apache-2.0 |

## How this marketplace is structured

This repo is **only** the Claude Code plugin manifest. The actual MCP server code lives on npm — the plugin's `.mcp.json` references its package via `npx`, so `/plugin install` does not vendor or clone the MCP source. The marketplace clone is small and fast.

The SceneView SDK itself (Android, iOS, Web, Flutter, RN) is at [github.com/sceneview/sceneview](https://github.com/sceneview/sceneview).

## Versioning

The plugin tracks the wrapped npm `sceneview-mcp` version. When `npm view sceneview-mcp version` ticks up, bump the plugin manifest:

```bash
bash scripts/sync-plugin-versions.sh         # report
bash scripts/sync-plugin-versions.sh --fix   # auto-bump plugin.json + marketplace.json
```

## Validate

```bash
claude plugin validate .                          # marketplace
claude plugin validate plugins/sceneview          # the plugin
```

## License

Apache-2.0 (see [`LICENSE`](LICENSE)). The plugin bundles the `sceneview-mcp` package which is itself MIT-licensed (verified via `npm view sceneview-mcp license`).
