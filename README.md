# SceneView Claude Code marketplace

A [Claude Code](https://www.anthropic.com/claude-code) plugin marketplace for [SceneView](https://github.com/sceneview/sceneview) and its high-traffic vertical MCP bridges.

## Quick install

```
/plugin marketplace add sceneview/claude-marketplace
/plugin install sceneview@sceneview
```

You can also pick any of the bridge plugins:

```
/plugin install realestate-3d@sceneview      # 3D listings, virtual tours, floor plans
/plugin install french-admin@sceneview       # impôts, URSSAF, CAF, ARE, Service-Public.fr
/plugin install ecommerce-3d@sceneview       # 3D product viewers, AR try-on, Shopify
/plugin install architecture-3d@sceneview    # 3D building concepts, lighting studies
```

## Plugins

| Plugin | Wraps | License |
|---|---|---|
| `sceneview` | [`sceneview-mcp`](https://www.npmjs.com/package/sceneview-mcp) — 28 tools, full SceneView API reference, code validator. Ships with 11 contributor commands and cross-platform reminder hooks. | Apache-2.0 |
| `realestate-3d` | [`realestate-mcp`](https://www.npmjs.com/package/realestate-mcp) — bilingual EN/FR property listings, virtual tours, floor plans, AR previews. | MIT |
| `french-admin` | [`french-admin-mcp`](https://www.npmjs.com/package/french-admin-mcp) — *impôts*, URSSAF, CAF, *Pôle Emploi* / *France Travail*, *Service-Public.fr* lookups. | MIT |
| `ecommerce-3d` | [`ecommerce-3d-mcp`](https://www.npmjs.com/package/ecommerce-3d-mcp) — 3D product viewers, AR try-on, Shopify-ready GLB. | MIT |
| `architecture-3d` | [`architecture-mcp`](https://www.npmjs.com/package/architecture-mcp) — 3D concepts, floor plans, material palettes, lighting studies. | MIT |

## How this marketplace is structured

This repo is **only** the Claude Code plugin manifests. The actual MCP server code lives on npm — each plugin's `.mcp.json` references its package via `npx`, so `/plugin install` does not vendor or clone the MCP source. Plugin manifests stay tiny (~1 kB each) and the marketplace clone is small and fast.

The SceneView SDK itself (Android, iOS, Web, Flutter, RN) is at [github.com/sceneview/sceneview](https://github.com/sceneview/sceneview).

## Versioning

Every plugin tracks its wrapped npm MCP version. When `npm view <pkg> version` ticks up, bump the plugin manifest:

```bash
bash scripts/sync-plugin-versions.sh         # report
bash scripts/sync-plugin-versions.sh --fix   # auto-bump plugin.json + marketplace.json
```

## Validate

```bash
claude plugin validate .                          # marketplace
claude plugin validate plugins/sceneview          # any single plugin
```

## License

Apache-2.0 (see [`LICENSE`](LICENSE)). Each plugin declares its own license inside `plugin.json`. Wrapped MCP packages are MIT (verified via `npm view <pkg> license`).
