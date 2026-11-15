#!/bin/bash
# Download ZOS's ESOUIDocumentation.txt (published in the esoui/esoui mirror) into .cache/ and
# print its path. Re-downloads when the cached copy is older than 7 days.
# Prints nothing and exits 1 when the file cannot be fetched and no cached copy exists.
# Usage: scripts/fetch-eso-api-doc.sh [branch]      (branch: live | pts, default live)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BRANCH="${1:-live}"
CACHE_DIR="${LAC_CACHE_DIR:-$ROOT/.cache}"
DOC="$CACHE_DIR/ESOUIDocumentation-${BRANCH}.txt"
URL="https://raw.githubusercontent.com/esoui/esoui/${BRANCH}/ESOUIDocumentation.txt"

mkdir -p "$CACHE_DIR"

fresh=0
if [ -s "$DOC" ] && [ -n "$(find "$DOC" -mtime -7 2>/dev/null)" ]; then
  fresh=1
fi

if [ "$fresh" -eq 0 ]; then
  tmp="$DOC.tmp"
  if curl --silent --show-error --fail --location --max-time 120 "$URL" -o "$tmp" 2>/dev/null \
    && grep -q "ESO UI Documentation for API Version" "$tmp"; then
    mv "$tmp" "$DOC"
  else
    rm -f "$tmp"
  fi
fi

if [ -s "$DOC" ]; then
  echo "$DOC"
else
  exit 1
fi
