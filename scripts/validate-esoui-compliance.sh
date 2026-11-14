#!/bin/bash
# LibApiCompose - ESOUI packaging / listing compliance (library)
# Usage:
#   scripts/validate-esoui-compliance.sh
#   scripts/validate-esoui-compliance.sh --static

set -euo pipefail

ADDON_NAME="LibApiCompose"
MANIFEST_FILE="${ADDON_NAME}.txt"
CORE_FILE="src/Core.lua"
README_ESOUI="README_ESOUI.txt"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

STATIC_ONLY=0
for arg in "$@"; do
    case "$arg" in
        --static) STATIC_ONLY=1 ;;
        -h|--help)
            echo "Usage: $0 [--static]"
            exit 0
            ;;
        *)
            echo "Unknown option: $arg"
            exit 1
            ;;
    esac
done

cd "$REPO_ROOT"

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'
PASSED=0
FAILED=0

ok() { echo -e "${GREEN}✅ $1${NC}"; PASSED=$((PASSED + 1)); }
fail() { echo -e "${RED}❌ $1${NC}"; FAILED=$((FAILED + 1)); }

validate_repo_layout() {
    echo ""
    echo "── Repo layout ──"
    if [ -f "$MANIFEST_FILE" ]; then
        ok "Manifest present: $MANIFEST_FILE"
    else
        fail "Missing PC manifest: $MANIFEST_FILE"
    fi
    if [ -f "${ADDON_NAME}.addon" ]; then
        fail "Console manifest ${ADDON_NAME}.addon must not exist for PC-only library"
    else
        ok "No ${ADDON_NAME}.addon (PC uses .txt)"
    fi
    if [ -f "$CORE_FILE" ]; then
        ok "Core.lua present"
    else
        fail "Missing $CORE_FILE"
    fi
}

validate_manifest_technical() {
    echo ""
    echo "── Manifest technical ──"
    if [ ! -f "$MANIFEST_FILE" ]; then
        fail "Missing $MANIFEST_FILE"
        return
    fi

    local runner=""
    if command -v lua >/dev/null 2>&1; then
        runner=lua
    elif command -v luajit >/dev/null 2>&1; then
        runner=luajit
    fi

    if [ -n "$runner" ]; then
        if $runner "$SCRIPT_DIR/validate-manifest.lua" "$MANIFEST_FILE"; then
            ok "validate-manifest.lua passed"
        else
            fail "validate-manifest.lua failed on $MANIFEST_FILE"
        fi
    fi

    if grep -qiE '^## IsLibrary:[[:space:]]*true' "$MANIFEST_FILE"; then
        ok "IsLibrary: true"
    else
        fail "Library manifest must set ## IsLibrary: true"
    fi

    if grep -q "^## SavedVariables:" "$MANIFEST_FILE"; then
        fail "Library should not declare SavedVariables (read-only compose lib)"
    else
        ok "No SavedVariables (library)"
    fi
}

validate_esoui_listing() {
    echo ""
    echo "── ESOUI listing (README_ESOUI.txt) ──"
    if [ ! -f "$README_ESOUI" ]; then
        fail "Missing $README_ESOUI"
        return
    fi

    if grep -q 'AI assistance' "$README_ESOUI"; then
        ok "AI disclosure present"
    else
        fail "README_ESOUI.txt must contain AI disclosure ('AI assistance')"
    fi

    if LC_ALL=C grep -n '[^[:print:][:space:]]' "$README_ESOUI" >/dev/null 2>&1; then
        fail "README_ESOUI.txt contains non-ASCII characters"
    else
        if command -v perl >/dev/null 2>&1; then
            if perl -ne 'exit 1 if /[^\x00-\x7F]/' "$README_ESOUI"; then
                ok "README_ESOUI.txt is ASCII-only"
            else
                fail "README_ESOUI.txt contains non-ASCII bytes"
            fi
        else
            ok "README_ESOUI.txt printable ASCII check passed"
        fi
    fi
}

validate_dist_zip() {
    echo ""
    echo "── Release ZIP ──"
    local zip_file
    zip_file=$(ls -t dist/${ADDON_NAME}-*.zip 2>/dev/null | head -1 || true)
    if [ -z "$zip_file" ] || [ ! -f "$zip_file" ]; then
        echo "   (no dist/${ADDON_NAME}-*.zip — skip artifact check)"
        return 0
    fi
    if bash "$SCRIPT_DIR/validate-zip.sh" "$zip_file"; then
        ok "Artifact ZIP valid: $(basename "$zip_file")"
    else
        fail "Artifact ZIP failed validation: $zip_file"
    fi
}

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " LibApiCompose — ESOUI compliance"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

validate_repo_layout
validate_manifest_technical
validate_esoui_listing

if [ "$STATIC_ONLY" -eq 0 ]; then
    validate_dist_zip
fi

echo ""
echo "Passed: $PASSED | Failed: $FAILED"
if [ "$FAILED" -ne 0 ]; then
    echo -e "${RED}❌ ESOUI compliance failed${NC}"
    exit 1
fi
echo -e "${GREEN}✅ ESOUI compliance passed${NC}"
exit 0
