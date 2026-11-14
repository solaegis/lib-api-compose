#!/bin/bash
# Set ## AddOnVersion: from semver (major*10000 + minor*100 + patch).
# Usage: scripts/set-addon-version.sh <manifest.txt> <semver>
# Example: 1.2.3 → 10203 ; 1.0.0 → 10000
# Non-semver (dev, SHA) → keep the committed integer in the manifest (dev floor), else 1.
# Fails if minor or patch >= 100 (the encoding would collide).

set -euo pipefail

MANIFEST="${1:?manifest path required}"
VERSION="${2:-}"

if [ ! -f "$MANIFEST" ]; then
    echo "❌ Manifest not found: $MANIFEST"
    exit 1
fi

if [ -z "$VERSION" ]; then
    if git rev-parse --git-dir >/dev/null 2>&1; then
        if git describe --tags --exact-match HEAD >/dev/null 2>&1; then
            VERSION=$(git describe --tags --exact-match HEAD | sed 's/^v//')
        else
            VERSION="0.0.0"
        fi
    else
        VERSION="0.0.0"
    fi
fi

# Strip leading v
VERSION="${VERSION#v}"

ENCODED=0
if [[ "$VERSION" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)([.-].*)?$ ]]; then
    MAJOR="${BASH_REMATCH[1]}"
    MINOR="${BASH_REMATCH[2]}"
    PATCH="${BASH_REMATCH[3]}"
    if [ "$MINOR" -ge 100 ] || [ "$PATCH" -ge 100 ]; then
        echo "❌ Version $VERSION: minor and patch must be < 100 for AddOnVersion encoding"
        exit 1
    fi
    ENCODED=$((MAJOR * 10000 + MINOR * 100 + PATCH))
elif [[ "$VERSION" =~ ^([0-9]+)\.([0-9]+)$ ]]; then
    MAJOR="${BASH_REMATCH[1]}"
    MINOR="${BASH_REMATCH[2]}"
    if [ "$MINOR" -ge 100 ]; then
        echo "❌ Version $VERSION: minor must be < 100 for AddOnVersion encoding"
        exit 1
    fi
    ENCODED=$((MAJOR * 10000 + MINOR * 100))
else
    # Untagged/dev builds: keep the committed integer so DependsOn>=N consumers still load.
    CURRENT=$(grep "^## AddOnVersion:" "$MANIFEST" | sed 's/^## AddOnVersion:[[:space:]]*//' | tr -d '\r')
    if [[ "$CURRENT" =~ ^[1-9][0-9]*$ ]]; then
        ENCODED="$CURRENT"
        echo "⚠️  Version '$VERSION' is not semver — keeping committed AddOnVersion ${ENCODED}"
    else
        ENCODED=1
        echo "⚠️  Version '$VERSION' is not semver — AddOnVersion set to 1"
    fi
fi

if [ "$(uname -s)" = "Darwin" ]; then
    sed -i '' "s/^## AddOnVersion: .*/## AddOnVersion: ${ENCODED}/" "$MANIFEST"
else
    sed -i "s/^## AddOnVersion: .*/## AddOnVersion: ${ENCODED}/" "$MANIFEST"
fi

# Also stamp LAC.ADDON_VERSION in Core.lua if present
CORE="$(dirname "$MANIFEST")/src/Core.lua"
if [ -f "$CORE" ]; then
    if [ "$(uname -s)" = "Darwin" ]; then
        sed -i '' "s/^LAC.ADDON_VERSION = .*/LAC.ADDON_VERSION = ${ENCODED}/" "$CORE" || true
    else
        sed -i "s/^LAC.ADDON_VERSION = .*/LAC.ADDON_VERSION = ${ENCODED}/" "$CORE" || true
    fi
fi

echo "✅ Set AddOnVersion to ${ENCODED} (from ${VERSION}) in $(basename "$MANIFEST")"
