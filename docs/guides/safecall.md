# SafeCall

`LAC.SafeCall` and `LAC.SafeCallMulti` are the library's foundation and its most widely useful export. Use them
for any ZOS call that might error or might not exist on the client.

## Which one?

Pick by how many return values you need, not by habit:

| You need | Use | Returns |
|---|---|---|
| The first return value | `LAC.SafeCall(fn, ...)` | value, or `nil` on failure |
| Two or more return values | `LAC.SafeCallMulti(fn, ...)` | `true, v1, v2, …` or `false, errorMessage` |

```lua
local LAC = LibApiCompose

local name = LAC.SafeCall(GetUnitName, "player")

local ok, icon, stack, sellPrice = LAC.SafeCallMulti(GetItemInfo, BAG_BACKPACK, 0)
if not ok then
    return
end
```

!!! danger "Don't use SafeCall for multi-return APIs"
    `local a, b = LAC.SafeCall(GetItemInfo, bag, slot)` gives you `b == nil` every time — `SafeCall` returns
    exactly one value. Use `SafeCallMulti`.

## `nil` holes are preserved

Plain `pcall` wrappers often lose trailing or embedded `nil`s. `SafeCallMulti` counts the values with
`select("#", ...)`, so `fn` returning `"a", nil, "c"` gives you `true, "a", nil, "c"`.

## Missing functions

If `fn` is `nil` or not a function — usually a ZOS API that was renamed or removed on this client —
`SafeCallMulti` returns `false, "SafeCallMulti: function is nil or not a function (type=nil)"` and
`SafeCall` returns `nil`. Nothing is logged, because a missing API is expected on older or newer clients.

So this is safe on every client:

```lua
local LAC = LibApiCompose
local quality = LAC.SafeCall(GetItemFunctionalQuality, BAG_BACKPACK, 0)
```

When there's a newer and an older API, branch on existence and fall back:

```lua
local LAC = LibApiCompose

local function itemQuality(bagId, slotIndex)
    if GetItemFunctionalQuality then
        return LAC.SafeCall(GetItemFunctionalQuality, bagId, slotIndex)
    end
    return LAC.SafeCall(GetItemQuality, bagId, slotIndex)
end
```

## Errors

On failure, `SafeCallMulti` returns `false` and the **original** error value (usually a string with file and
line). `SafeCall` throws that away and returns `nil`.

When [LibDebugLogger](https://www.esoui.com/downloads/info2275-LibDebugLogger.html) is installed, each distinct
failure is logged once under the `LibApiCompose` tag — including calls to a function that doesn't exist on the
client. Run `LibApiCompose.SetDebug(true)` to add full tracebacks and find the failing call in the
DebugLogViewer. Without LibDebugLogger, failures are silent.

After a game patch, `/script d(LibApiCompose.SelfTest())` lists any ZOS function or constant the library reads
that no longer exists.

## Arguments are passed through unchanged

```lua
local LAC = LibApiCompose
local count = LAC.SafeCall(GetItemTotalCount, BAG_BACKPACK, 0)
local ok = LAC.SafeCallMulti(function(a, b, c)
    return a, b, c
end, 1, nil, 3) -- the nil argument reaches the function
```

## Performance

`SafeCall` is a `pcall` plus a small table for the return values. That's cheap enough for event handlers and
list builds; avoid it in per-frame `OnUpdate` code only because you shouldn't be calling ZOS there at all.
With LibDebugLogger installed, each call also builds one closure for `xpcall`.

## Anti-patterns

| Don't | Do |
|---|---|
| `pcall(GetItemInfo, bag, slot)` and pick values by hand | `LAC.SafeCallMulti(GetItemInfo, bag, slot)` |
| `local x = LAC.SafeCall(F) ; if x == false then` to detect errors | `local ok, x = LAC.SafeCallMulti(F)` |
| Wrap your own addon's functions to hide bugs | Let your own code error; SafeCall is for the ZOS boundary |
| `LAC.SafeCall(SomeProtectedFunction)` from insecure code | Call protected functions through `CallSecureProtected` in your addon |
