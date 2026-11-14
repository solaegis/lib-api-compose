# Lua patterns

ESO runs **Lua 5.1**. Never use `goto` / labels.

## Namespace

```lua
MyAddon = MyAddon or {}
local MA = MyAddon
```

All product code lives on the global table or via the local alias. Do not pollute `_G` with helpers.

## SafeCall

Use `SAT.SafeCall` for single-return ESO API calls. Use `SAT.SafeCallMulti` (or raw `pcall`) when you need multiple returns.

```lua
local value = SAT.SafeCall(SomeApi, arg) or defaultValue

local ok, a, b, c = SAT.SafeCallMulti(GetMultipleValues, id)
if not ok then
    SAT.Error("failed: " .. tostring(a))
    return
end
```

## Logging

| API | When |
|-----|------|
| `SAT.Info` / `Warn` / `Error` | User-visible chat (+ LibDebugLogger when present) |
| `SAT.DebugPrint(category, msg)` | Silent unless logger or debug mode |
| `SAT.Chat` | Support footer / always-on chat |
| `d()` | Avoid for product messages |

## LibAddonMenu

- No emoji or Unicode icons in names/tooltips (they render as boxes).
- `choices`, `choicesValues`, and `tooltips` must be the **same length**. A `nil` inside a Lua table constructor silently shortens `#tbl` and trips LAM asserts — use a non-nil sentinel (e.g. `"none"`).
- Wire `defaultsFunc` to your reset that **preserves** `perCharacterData`.
- Append `SAT.AppendSupportFooter(optionsTable)` at the end of the options list.

## Commands

- Primary slash + long alias (`/sat`, `/solaegisaddontemplate`).
- As commands grow, prefer `object:action` subcommands (e.g. `filter:clear`).
- Open settings gracefully when LAM is missing.

## Performance

- Cache frequently used globals at module scope when hot paths matter.
- Prefer `table.concat` for string building.
- Unregister one-shot event handlers after they fire.
