#!/bin/bash
# Documentation drift check.
#  1. Every public function defined in src/*.lua (function LAC.X / function Module.X, name not starting
#     with "_") must have a "### `Module.X`" heading in docs/reference/.
#  2. Every fenced ```lua block under docs/ must parse as Lua.
# Usage: scripts/check-api-docs.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

failed=0

# --- 1. Reference coverage -------------------------------------------------
missing=()
while IFS= read -r name; do
  if ! grep -rqF -- "### \`${name}\`" docs/reference/; then
    missing+=("$name")
  fi
done < <(grep -hoE '^function [A-Za-z]+\.[A-Za-z][A-Za-z0-9]*' src/*.lua \
          | sed 's/^function //' \
          | grep -vE '\._' \
          | sort -u)

if [ "${#missing[@]}" -gt 0 ]; then
  echo "❌ Public functions without a reference entry in docs/reference/:"
  for name in "${missing[@]}"; do
    echo "   - ${name}   (add a heading: ### \`${name}\`)"
  done
  failed=1
else
  echo "✅ Every public function has a reference entry"
fi

# --- 2. Lua examples parse -------------------------------------------------
LUA_BIN=""
if command -v luajit >/dev/null 2>&1; then
  LUA_BIN=luajit
elif command -v lua >/dev/null 2>&1; then
  LUA_BIN=lua
fi

if [ -z "$LUA_BIN" ]; then
  echo "⚠️  lua/luajit not found — skipping example syntax check"
else
  # Prints "file:line" for each lua block that fails to parse.
  bad=$(find docs -name '*.md' -print0 | xargs -0 "$LUA_BIN" -e '
    local loader = loadstring or load
    local failures = 0
    for i = 1, #arg do
      local path = arg[i]
      local f = assert(io.open(path, "r"))
      local inBlock, startLine, buf, lineNo = false, 0, {}, 0
      for line in f:lines() do
        lineNo = lineNo + 1
        if not inBlock and line:match("^%s*```lua%s*$") then
          inBlock, startLine, buf = true, lineNo, {}
        elseif inBlock and line:match("^%s*```%s*$") then
          inBlock = false
          local ok, err = loader(table.concat(buf, "\n"), "=" .. path .. ":" .. startLine)
          if not ok then
            print(err)
            failures = failures + 1
          end
        elseif inBlock then
          buf[#buf + 1] = line
        end
      end
      f:close()
    end
    os.exit(failures == 0 and 0 or 1)
  ' -- ) || true
  if [ -n "$bad" ]; then
    echo "❌ Lua examples that do not parse:"
    echo "$bad" | sed 's/^/   - /'
    failed=1
  else
    echo "✅ Every lua example parses"
  fi
fi

exit "$failed"
