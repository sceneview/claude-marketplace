# SceneView plugin for Claude Code

Build 3D and AR apps with [SceneView](https://github.com/sceneview/sceneview), the open-source
3D & AR SDK for Android (Jetpack Compose), iOS / macOS / visionOS (SwiftUI) and the web.

This plugin carries the same three skills and the same MCP server that SceneView ships for every
other assistant (Codex, Gemini CLI, Cursor, Copilot and others): see
[AI-assisted development](https://sceneview.github.io/docs/ai-development/) for the equivalent setup
in each tool.

## What you get

- **Three skills**, loaded when the task matches:
  - `sceneview`: Android, Jetpack Compose + Filament + ARCore (also covers Flutter and React Native)
  - `sceneview-ios`: SwiftUI + RealityKit on iOS, macOS and visionOS (SceneViewSwift)
  - `sceneview-web`: Filament.js (WebGL2/WASM) + WebXR in the browser

  Each one carries the API contract, compilable recipes, a cheatsheet and a migration guide.
- **The `sceneview-mcp` server**, started automatically: compilable samples, platform setup
  guides, a code validator, node references and 3D model search.

## Install

```
/plugin marketplace add sceneview/claude-marketplace
/plugin install sceneview@sceneview
```

Then ask for what you want to build, for example *"a Compose screen that loads a .glb with an
orbit camera"* or *"place this model on a detected plane with ARCore"*.

## Where the skills come from

The skills are copied from [`agents/`](https://github.com/sceneview/sceneview/tree/main/agents)
in the SDK repository, the single source shared with the Codex plugin and the `android-cli`
skill registry. `scripts/sync-plugin-versions.sh` in this marketplace reports any drift and
`--fix` refreshes the copies.

## Contributing to SceneView itself?

The maintainer commands (`/release`, `/version-bump`, `/review`...) live in a separate plugin,
`sceneview-contrib`, because they only make sense inside a checkout of the SDK repository.

## Links

- Docs: https://sceneview.github.io
- API reference: https://github.com/sceneview/sceneview/blob/main/llms.txt
- Issues: https://github.com/sceneview/sceneview/issues
- Support the project: https://opencollective.com/sceneview

## License

Apache-2.0. The bundled `sceneview-mcp` npm package is MIT.
