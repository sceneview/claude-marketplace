# SceneView contributor plugin for Claude Code

For people working **on** the [SceneView](https://github.com/sceneview/sceneview) SDK repository.
To build apps with SceneView, install the `sceneview` plugin instead.

The commands are plain Markdown files in [`commands/`](commands), so a contributor using another
assistant can point it at the same file.

## Install

```
/plugin marketplace add sceneview/claude-marketplace
/plugin install sceneview-contrib@sceneview
```

## Commands

Run them from a checkout of `sceneview/sceneview`; they call the scripts in its `.claude/scripts/`.

| Command | What it does |
|---|---|
| `/sceneview-contrib:contribute` | Guided workflow: read the codebase, scope the change, prepare a PR |
| `/sceneview-contrib:review` | Threading, Compose API, style and module-boundary review |
| `/sceneview-contrib:test` | Run and extend the relevant test suites |
| `/sceneview-contrib:document` | Update KDoc for changed public APIs and `llms.txt` |
| `/sceneview-contrib:evaluate` | Weighted quality evaluation of a change |
| `/sceneview-contrib:quality-gate` | Pre-PR checks |
| `/sceneview-contrib:sync-check` | Cross-platform and version sync checks |
| `/sceneview-contrib:publish-check` | Pre-release checks across registries |
| `/sceneview-contrib:version-bump` | Bump the SDK version everywhere it is derived |
| `/sceneview-contrib:release` | Coordinated multi-platform release |
| `/sceneview-contrib:maintain` | Repository maintenance pass |

`review` and `test` share their names with built-in commands, so use the prefixed form.

## Hooks

After an `Edit` or `Write`, reminder hooks print a one-line note when the edited path is
`gradle.properties` or an Android, Swift, web or KMP-core source directory, so API changes keep
parity across platforms. They only print text; they never block or modify anything.

## License

Apache-2.0.
