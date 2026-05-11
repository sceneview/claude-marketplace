#!/usr/bin/env bash
# sync-plugin-versions.sh — Verify each Claude Code plugin's manifest
# version matches the npm-published version of the MCP it wraps.
#
# This marketplace ships ONE plugin (sceneview) per the strict org-scope rule
# (see memory `feedback_sceneview_org_strict`). The plugin tracks the wrapped
# `sceneview-mcp` npm package version, NOT the SDK gradle.properties VERSION_NAME.
#
# Usage:
#   bash scripts/sync-plugin-versions.sh           # report only
#   bash scripts/sync-plugin-versions.sh --fix     # auto-bump plugin.json + marketplace.json
#
# Exit codes:
#   0 = plugin aligned with its wrapped npm package
#   1 = mismatch (or fixed if --fix)
#   2 = script error (missing dependencies, network failure, malformed JSON)

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FIX_MODE="${1:-}"
ERRORS=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}=== Plugin ↔ npm version sync ===${NC}"
echo ""

# Mapping: plugin folder | wrapped npm package name
# This marketplace ships ONE plugin (sceneview). Off-topic personal-portfolio
# MCPs live in their own orgs and have their own marketplaces — never here.
PLUGINS=(
    "sceneview|sceneview-mcp"
)

MARKETPLACE_JSON="$REPO_ROOT/.claude-plugin/marketplace.json"
if [ ! -f "$MARKETPLACE_JSON" ]; then
    echo -e "${RED}FATAL: $MARKETPLACE_JSON not found${NC}"
    exit 2
fi

for entry in "${PLUGINS[@]}"; do
    plugin_dir="${entry%%|*}"
    npm_pkg="${entry##*|}"
    plugin_json="$REPO_ROOT/plugins/$plugin_dir/.claude-plugin/plugin.json"

    if [ ! -f "$plugin_json" ]; then
        echo -e "  ${YELLOW}SKIP${NC}  $plugin_dir (plugin.json not found)"
        continue
    fi

    plugin_version=$(python3 -c "import json; print(json.load(open('$plugin_json'))['version'])" 2>/dev/null || echo "MISSING")
    npm_version=$(npm view "$npm_pkg" version 2>/dev/null || echo "NETWORK_ERROR")
    marketplace_version=$(python3 -c "import json; m=json.load(open('$MARKETPLACE_JSON')); p=[x for x in m['plugins'] if x['name']=='$plugin_dir'][0]; print(p.get('version','MISSING'))" 2>/dev/null || echo "MISSING")

    label=$(printf '  %-18s' "$plugin_dir")
    if [ "$plugin_version" = "$npm_version" ] && [ "$marketplace_version" = "$npm_version" ]; then
        echo -e "${label}plugin=$plugin_version  marketplace=$marketplace_version  npm=$npm_version  ${GREEN}OK${NC}"
    elif [ "$npm_version" = "NETWORK_ERROR" ]; then
        echo -e "${label}plugin=$plugin_version  marketplace=$marketplace_version  npm=${RED}network error${NC} ${YELLOW}SKIP${NC}"
    else
        ERRORS=$((ERRORS + 1))
        echo -e "${label}plugin=$plugin_version  marketplace=$marketplace_version  npm=$npm_version  ${RED}MISMATCH${NC}"

        if [ "$FIX_MODE" = "--fix" ]; then
            python3 - <<EOF
import json, pathlib
pj = pathlib.Path("$plugin_json")
data = json.loads(pj.read_text())
data["version"] = "$npm_version"
pj.write_text(json.dumps(data, indent=2) + "\n")
print(f"  fixed: {pj.relative_to('$REPO_ROOT')} -> $npm_version")

mj = pathlib.Path("$MARKETPLACE_JSON")
m = json.loads(mj.read_text())
for p in m["plugins"]:
    if p["name"] == "$plugin_dir":
        p["version"] = "$npm_version"
mj.write_text(json.dumps(m, indent=2) + "\n")
print(f"  fixed: marketplace.json plugins[$plugin_dir].version -> $npm_version")
EOF
        fi
    fi
done

echo ""
if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}All bridge plugins aligned with their wrapped npm packages${NC}"
    exit 0
else
    if [ "$FIX_MODE" = "--fix" ]; then
        echo -e "${GREEN}Fixed $ERRORS mismatch(es). Re-run without --fix to verify.${NC}"
        exit 0
    else
        echo -e "${RED}$ERRORS bridge plugin(s) out of sync. Run with --fix to auto-bump.${NC}"
        exit 1
    fi
fi
