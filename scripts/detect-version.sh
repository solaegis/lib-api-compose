#!/bin/bash
# Print the build version derived from git.
#   exact tag vX.Y.Z  -> X.Y.Z
#   --describe        -> `git describe --tags` (e.g. 1.0.0-3-gabc123) when not on a tag
#   otherwise         -> short commit SHA, or "dev" outside a git checkout
# Usage: scripts/detect-version.sh [--describe]
set -euo pipefail

ALLOW_DESCRIBE=0
if [ "${1:-}" = "--describe" ]; then
  ALLOW_DESCRIBE=1
fi

if ! git rev-parse --git-dir >/dev/null 2>&1 || ! git rev-parse HEAD >/dev/null 2>&1; then
  echo "dev"
  exit 0
fi

if git describe --tags --exact-match HEAD >/dev/null 2>&1; then
  git describe --tags --exact-match HEAD | sed 's/^v//'
elif [ "$ALLOW_DESCRIBE" -eq 1 ] && git describe --tags >/dev/null 2>&1; then
  git describe --tags | sed 's/^v//'
else
  git rev-parse --short HEAD
fi
