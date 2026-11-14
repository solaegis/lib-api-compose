# Lua patterns

Conventions for code inside LibApiCompose. ESO runs **Lua 5.1**.

## Language

- No `goto` / labels, no `//`, no bitwise operators, no `table.unpack` (use `unpack`), no `#` on tables with
  holes.
- `select("#", ...)` to count varargs; `{ ... }` plus `unpack(t, 1, n)` to forward them with `nil`s intact.
- Wrap `gsub` in parentheses when returning it: `return (s:gsub(a, b))` — it returns two values.

## Module shape

Every domain file follows the same layout:

```lua
-- LibApiCompose — Module.Function (style X)

local LAC = LibApiCompose
LAC.Module = LAC.Module or {}
local Module = LAC.Module
local SafeCall = LAC.SafeCall

local function helper(arg)
    return SafeCall(GetSomething, arg)
end

--- One-line summary.
--- Identity: fieldA, fieldB
--- Fields: fieldC, fieldD
function Module.Compose(handle, opts)
    opts = opts or {}
    if handle == nil then
        return nil
    end
    return {
        handle = handle,
        value = helper(handle),
    }
end
```

- `LAC.Module = LAC.Module or {}` so a reload doesn't wipe state another file attached.
- Cache `LAC.SafeCall` in a local at file scope; it's defined in Core, which loads first.
- Private helpers are `local function`. Helpers shared between files go on `LAC._internal`.
- Never create globals. The only global is `LibApiCompose`.

## Calling ZOS

```lua
local LAC = LibApiCompose
local SafeCall = LAC.SafeCall

local function readItem(bagId, slotIndex)
    -- single return
    local itemType = SafeCall(GetItemType, bagId, slotIndex)

    -- multiple returns: check ok, reset on failure
    local ok, icon, _, sellPrice = LAC.SafeCallMulti(GetItemInfo, bagId, slotIndex)
    if not ok then
        icon, sellPrice = nil, nil
    end

    -- old/new API pair: branch on existence
    local quality
    if GetItemFunctionalQuality then
        quality = SafeCall(GetItemFunctionalQuality, bagId, slotIndex)
    else
        quality = SafeCall(GetItemQuality, bagId, slotIndex)
    end

    -- booleans: normalise
    local bound = SafeCall(IsItemBound, bagId, slotIndex) == true

    return itemType, icon, sellPrice, quality, bound
end
```

- No raw `pcall` in domain files.
- No `if GetX then` guard around a single call — `SafeCall` already soft-fails on a missing function. Guard only
  when choosing between alternatives.
- Optional ZOS constants: compare against `nil` first (`if BAG_VIRTUAL ~= nil and bagId == BAG_VIRTUAL`).

## Records

- Build the return table in one constructor at the end, so the shape is visible in one place.
- Keep identity fields first.
- For "same shape regardless" records (Gear on non-gear), set defaults first and fill in afterwards.

## Logging

- `LAC.DebugPrint(category, msgOrFn)` only. Pass a function when building the message is expensive.
- Never `d()` or chat output from the library.

## Performance

- Avoid composing in loops when a cheaper check can filter first.
- Don't allocate closures per call in hot paths.
- Prefer `table.concat` to repeated `..` when building long strings.
