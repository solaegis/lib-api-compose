#!/bin/bash
# LibApiCompose - ESOUI API upload helper
# The API key is read from the ESOUI_API_KEY environment variable (never argv, which is
# visible in the process list).
# Usage: ESOUI_API_KEY=... scripts/esoui-upload.sh <addon_id> <version> <zip> \
#            [compatible_version] [changelog_file] [description_file] [test_mode]

set -euo pipefail

API_KEY="${ESOUI_API_KEY:?ESOUI_API_KEY environment variable required}"
ADDON_ID="${1:?Addon ID required}"
VERSION="${2:?Addon version required}"
ZIP_FILE="${3:?ZIP file path required}"
COMPATIBLE_VERSION="${4:-}"
CHANGELOG_FILE="${5:-CHANGELOG.md}"
DESCRIPTION_FILE="${6:-README_ESOUI.txt}"
TEST_MODE="${7:-false}"

if ! [[ "$ADDON_ID" =~ ^[0-9]+$ ]]; then
    echo "Addon ID must be numeric: $ADDON_ID" >&2
    exit 1
fi

if [ ! -f "$ZIP_FILE" ]; then
    echo "ZIP file not found: $ZIP_FILE" >&2
    exit 1
fi

ENDPOINT="https://api.esoui.com/addons/update"
if [ "$TEST_MODE" = "true" ]; then
    ENDPOINT="https://api.esoui.com/addons/updatetest"
    echo "ESOUI test upload (no changes saved)"
fi

COMPATIBLE="$COMPATIBLE_VERSION"
if [ -n "$COMPATIBLE_VERSION" ] && command -v jq >/dev/null 2>&1; then
    if COMPATIBLE_LIST="$(curl --silent --fail -H "x-api-token: ${API_KEY}" \
        "https://api.esoui.com/addons/compatible.json")"; then
        RESOLVED="$(echo "$COMPATIBLE_LIST" | jq -r --arg v "$COMPATIBLE_VERSION" '
            [ .[] | select((.version // "" | tostring) == $v or ((.name // "") | test($v)))]
            | first | (.id // empty) | tostring
        ')"
        if [ -n "$RESOLVED" ]; then
            COMPATIBLE="$RESOLVED"
        fi
    fi
fi

CURL_ARGS=(
    --silent --show-error --fail -X POST
    -H "x-api-token: ${API_KEY}"
    --form-string "id=${ADDON_ID}"
    --form-string "version=${VERSION}"
    -F "updatefile=@${ZIP_FILE}"
)

[ -f "$CHANGELOG_FILE" ] && CURL_ARGS+=(-F "changelog=<${CHANGELOG_FILE}")
[ -f "$DESCRIPTION_FILE" ] && CURL_ARGS+=(-F "description=<${DESCRIPTION_FILE}")
[ -n "$COMPATIBLE" ] && CURL_ARGS+=(--form-string "compatible=${COMPATIBLE}")

curl "${CURL_ARGS[@]}" "$ENDPOINT"
echo ""
echo "ESOUI upload accepted (compatible=${COMPATIBLE:-unset})"
