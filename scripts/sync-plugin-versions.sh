#!/usr/bin/env bash
# sync-plugin-versions.sh — Verify that the sceneview plugin's skills match
# agents/ in sceneview/sceneview, and that its version is the SDK version those
# skills describe (VERSION_NAME in the SDK's gradle.properties).
#
# This marketplace ships only SceneView plugins (sceneview, sceneview-contrib):
# the org publishes only what it maintains. The sceneview plugin carries skills
# only; it wraps no npm package, so its version follows the SDK release whose
# API and dependency lines the skills give.
#
# Usage:
#   bash scripts/sync-plugin-versions.sh           # report only
#   bash scripts/sync-plugin-versions.sh --fix     # bump plugin.json + marketplace.json
#                                                  # and refresh the skill copies
#
# The sceneview-contrib plugin is versioned by hand.
# SCENEVIEW_SRC=<checkout> compares against a local checkout instead of a
# shallow clone of GitHub main.
#
# Exit codes:
#   0 = plugin aligned with the SDK version and its skill sources
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

PLUGIN_DIR="sceneview"
PLUGIN_JSON="$REPO_ROOT/plugins/$PLUGIN_DIR/.claude-plugin/plugin.json"
MARKETPLACE_JSON="$REPO_ROOT/.claude-plugin/marketplace.json"
SKILLS_DIR="$REPO_ROOT/plugins/$PLUGIN_DIR/skills"
for f in "$PLUGIN_JSON" "$MARKETPLACE_JSON"; do
    if [ ! -f "$f" ]; then
        echo -e "${RED}FATAL: $f not found${NC}"
        exit 2
    fi
done

# Skills of agents/ this plugin does not ship. sceneview-ios documents
# SceneViewSwift, end of life at 4.68.0 (DEPRECATION.md in the SDK repo): it
# stays in agents/ for existing apps but is not offered to new ones.
NOT_SHIPPED="sceneview-ios"

# --- SDK source: a local checkout or a shallow sparse clone of main ---------
SRC="${SCENEVIEW_SRC:-}"
if [ -n "$SRC" ]; then
    if [ ! -d "$SRC/agents" ] || [ ! -f "$SRC/gradle.properties" ]; then
        echo -e "  ${RED}FATAL${NC}  SCENEVIEW_SRC=$SRC has no agents/ or gradle.properties"
        exit 2
    fi
else
    TMP_SRC="$(mktemp -d)"
    trap 'rm -rf "$TMP_SRC"' EXIT
    # Cone-mode sparse checkout keeps the top-level files, gradle.properties included.
    if git clone -q --depth 1 --filter=blob:none --sparse \
            https://github.com/sceneview/sceneview.git "$TMP_SRC/sv" 2>/dev/null \
        && git -C "$TMP_SRC/sv" sparse-checkout set agents 2>/dev/null \
        && [ -d "$TMP_SRC/sv/agents" ] && [ -f "$TMP_SRC/sv/gradle.properties" ]; then
        SRC="$TMP_SRC/sv"
    else
        # A silent skip would turn CI green without checking anything.
        echo -e "  ${RED}FATAL${NC}  could not fetch sceneview/sceneview (network?)"
        exit 2
    fi
fi

# --- Plugin version ↔ SDK VERSION_NAME --------------------------------------
echo -e "${CYAN}=== Plugin version ↔ SDK VERSION_NAME ===${NC}"
sdk_version=$(sed -n 's/^VERSION_NAME=//p' "$SRC/gradle.properties" | head -1)
if [ -z "$sdk_version" ]; then
    echo -e "  ${RED}FATAL${NC}  no VERSION_NAME in $SRC/gradle.properties"
    exit 2
fi
plugin_version=$(python3 -c "import json; print(json.load(open('$PLUGIN_JSON'))['version'])" 2>/dev/null || echo "MISSING")
marketplace_version=$(python3 -c "import json; m=json.load(open('$MARKETPLACE_JSON')); p=[x for x in m['plugins'] if x['name']=='$PLUGIN_DIR'][0]; print(p.get('version','MISSING'))" 2>/dev/null || echo "MISSING")

label=$(printf '  %-18s' "$PLUGIN_DIR")
if [ "$plugin_version" = "$sdk_version" ] && [ "$marketplace_version" = "$sdk_version" ]; then
    echo -e "${label}plugin=$plugin_version  marketplace=$marketplace_version  sdk=$sdk_version  ${GREEN}OK${NC}"
else
    ERRORS=$((ERRORS + 1))
    echo -e "${label}plugin=$plugin_version  marketplace=$marketplace_version  sdk=$sdk_version  ${RED}MISMATCH${NC}"
    if [ "$FIX_MODE" = "--fix" ]; then
        # Textual substitution, not a json.dumps round-trip: the round-trip
        # rewrote the whole file for a five-character bump (escaped the em-dash,
        # exploded one-line arrays). The JSON is parsed afterwards to prove the
        # value landed.
        python3 - <<EOF
import json, pathlib, re, sys

def bump(path, pattern, label):
    p = pathlib.Path(path)
    src = p.read_text()
    new, n = re.subn(pattern, lambda m: m.group(1) + "$sdk_version" + m.group(3), src, count=1)
    if n != 1:
        sys.exit(f"  ERROR: no version field found in {label} — fix it by hand")
    p.write_text(new)
    print(f"  fixed: {label} -> $sdk_version")

bump("$PLUGIN_JSON", r'("version"\s*:\s*")([^"]+)(")', "$PLUGIN_DIR/.claude-plugin/plugin.json")
# Anchored on "source", not on "name": marketplace.json ALSO carries a
# top-level "name": "$PLUGIN_DIR" followed by metadata.version, so anchoring on
# the name would bump the marketplace's own version instead of the plugin's.
bump("$MARKETPLACE_JSON",
     r'("source"\s*:\s*"\./plugins/$PLUGIN_DIR"(?:.|\n)*?"version"\s*:\s*")([^"]+)(")',
     "marketplace.json plugins[$PLUGIN_DIR].version")

assert json.loads(pathlib.Path("$PLUGIN_JSON").read_text())["version"] == "$sdk_version"
m = json.loads(pathlib.Path("$MARKETPLACE_JSON").read_text())
assert [x for x in m["plugins"] if x["name"] == "$PLUGIN_DIR"][0]["version"] == "$sdk_version"
EOF
    fi
fi

# --- Skills ↔ sceneview/sceneview agents/ -----------------------------------
# The plugin ships copies of the skills that live in agents/ of the SDK repo
# (the same source the Codex plugin reads), minus NOT_SHIPPED. Each copy is
# compared file by file; --fix refreshes it.
echo ""
echo -e "${CYAN}=== Skills ↔ sceneview/sceneview agents/ ===${NC}"
# A skill is a directory of agents/ holding a SKILL.md, on either side.
upstream=$(cd "$SRC/agents" && for d in */; do if [ -f "$d/SKILL.md" ]; then echo "${d%/}"; fi; done | grep -vxF -f <(tr ' ' '\n' <<<"$NOT_SHIPPED") | sort || true)
local_skills=$( (cd "$SKILLS_DIR" 2>/dev/null && for d in */; do if [ -f "$d/SKILL.md" ]; then echo "${d%/}"; fi; done) | sort || true)
for skill in $(printf '%s\n%s\n' "$upstream" "$local_skills" | sort -u); do
    label=$(printf '  %-18s' "$skill")
    if ! grep -qx "$skill" <<<"$upstream"; then
        ERRORS=$((ERRORS + 1))
        echo -e "${label}${RED}NOT SHIPPED${NC} (gone from agents/ upstream, or listed in NOT_SHIPPED)"
        if [ "$FIX_MODE" = "--fix" ]; then
            rm -rf "${SKILLS_DIR:?}/$skill"
            echo "  fixed: plugins/$PLUGIN_DIR/skills/$skill removed"
        fi
        continue
    fi
    # Whole skill directory, except agents/<skill>/agents/openai.yaml: that is
    # Codex display metadata and does not belong in a Claude Code plugin.
    if diff -rq --exclude=agents "$SRC/agents/$skill" "$SKILLS_DIR/$skill" >/dev/null 2>&1; then
        echo -e "${label}${GREEN}OK${NC}"
    else
        ERRORS=$((ERRORS + 1))
        echo -e "${label}${RED}DRIFT${NC} from agents/$skill"
        if [ "$FIX_MODE" = "--fix" ]; then
            rm -rf "${SKILLS_DIR:?}/$skill"
            mkdir -p "$SKILLS_DIR"
            cp -R "$SRC/agents/$skill" "$SKILLS_DIR/$skill"
            rm -rf "${SKILLS_DIR:?}/$skill/agents"
            echo "  fixed: plugins/$PLUGIN_DIR/skills/$skill refreshed"
        fi
    fi
done

echo ""
if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}Plugin version and skills in sync${NC}"
    exit 0
else
    if [ "$FIX_MODE" = "--fix" ]; then
        echo -e "${GREEN}Fixed $ERRORS mismatch(es). Re-run without --fix to verify.${NC}"
        exit 0
    else
        echo -e "${RED}$ERRORS item(s) out of sync. Run with --fix to bump the version and refresh skills.${NC}"
        exit 1
    fi
fi
