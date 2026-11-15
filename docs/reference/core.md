# Core

`src/Core.lua` — loaded first. Defines the `LibApiCompose` global, SafeCall, keys, name helpers and cache control.

## Functions

### `LAC.SafeCall`

```text
LAC.SafeCall(fn, ...) -> any | nil
```

Calls `fn(...)` in protected mode and returns its **first** return value. Returns `nil` if `fn` errors or isn't a
function.

| Parameter | Type | Description |
|---|---|---|
| `fn` | `function` | Usually a ZOS API. `nil` is allowed and returns `nil`. |
| `...` | any | Passed through unchanged, `nil`s included. |

**Returns:** the first value `fn` returned, or `nil`.

**Logging:** when LibDebugLogger is installed, each *distinct* failure — an error, or a call with a missing
function — is logged once at warning level (repeats are suppressed until `LAC.ClearCache()`).
`LAC.SetDebug(true)` adds tracebacks. Nothing is ever printed to chat.

**Cost:** one `pcall`, no allocations.

```lua
local LAC = LibApiCompose
local name = LAC.SafeCall(GetUnitName, "player") or ""
```

See the [SafeCall guide](../guides/safecall.md). *Since 1.0.0.*

### `LAC.SafeCallMulti`

```text
LAC.SafeCallMulti(fn, ...) -> true, ... | false, error
```

Calls `fn(...)` in protected mode and returns every return value, preserving `nil`s between them.

| Parameter | Type | Description |
|---|---|---|
| `fn` | `function` | The function to call. |
| `...` | any | Passed through unchanged. |

**Returns:**

| On | Values |
|---|---|
| success | `true`, then every value `fn` returned |
| `fn` raised an error | `false`, the original error value |
| `fn` is not a function | `false`, `"SafeCallMulti: function is nil or not a function (type=<type>)"` |

```lua
local LAC = LibApiCompose
local ok, hasCharges, header = LAC.SafeCallMulti(GetItemLinkEnchantInfo, "|H0:item:1|h|h")
if ok then
    d(header)
end
```

*Since 1.0.0.*

### `LAC.SetDebug`

```text
LAC.SetDebug(enabled)
```

Turns debug mode on (`true`) or off. In debug mode, with LibDebugLogger installed, failed calls are logged with
a full traceback so you can find the call site. It costs a closure and two tables per `SafeCall`, so leave it
off outside troubleshooting. The setting is shared by every addon using the library and is not saved.

```lua
LibApiCompose.SetDebug(true)
```

*Since 1.0.0.*

### `LAC.IsDebug`

```text
LAC.IsDebug() -> boolean
```

Whether debug mode is on.

*Since 1.0.0.*

### `LAC.SelfTest`

```text
LAC.SelfTest() -> { ok, total, missing }
```

Checks that every ZOS function and constant the library reads exists on the running client.

| Key | Type | Meaning |
|---|---|---|
| `ok` | `integer` | symbols present |
| `total` | `integer` | symbols checked |
| `missing` | `table` | array of names that are `nil` on this client |

Run it after a game patch: `/script d(LibApiCompose.SelfTest())`. A non-empty `missing` means ZOS renamed or
removed something and the fields read from it are soft-failing to `nil`.

*Since 1.0.0.*

### `LAC.DebugPrint`

```text
LAC.DebugPrint(category, message)
```

Writes `"[category] message"` to LibDebugLogger at debug level. Does nothing when LibDebugLogger isn't
installed.

| Parameter | Type | Description |
|---|---|---|
| `category` | `string` | Short tag, e.g. `"SAFECALL"`. |
| `message` | `string \| function` | Text, or a function returning text (only called when a logger exists, so expensive formatting is skipped). |

*Since 1.0.0.*

### `LAC.AtLeast`

```text
LAC.AtLeast(n) -> boolean
```

True when the loaded library's encoded `AddOnVersion` (`LAC.ADDON_VERSION`) is `>= n`.

| Parameter | Type | Description |
|---|---|---|
| `n` | `integer` | Encoded version: `major*10000 + minor*100 + patch`. |

```lua
local LAC = LibApiCompose
if LAC.AtLeast(10100) then
    d("1.1.0 or newer")
end
```

See [Versioning](../getting-started/versioning.md). *Since 1.0.0.*

### `LAC.SlotKey`

```text
LAC.SlotKey(bagId, slotIndex) -> integer
```

One number identifying a bag slot: `bagId * LAC.KEY_STRIDE + slotIndex`. Unique for every bag, including the
craft bag where `slotIndex` is the item id. Non-numeric arguments count as `0`.

*Since 1.0.0.*

### `LAC.HotbarSlotKey`

```text
LAC.HotbarSlotKey(hotbarCategory, slotIndex) -> integer
```

One number identifying a hotbar slot: `hotbarCategory * LAC.KEY_STRIDE + slotIndex`.

*Since 1.0.0.*

### `LAC.FormatName`

```text
LAC.FormatName(name) -> string | name
```

Returns a display name with ZOS grammar suffixes removed (`"Mirri Elendis^F"` → `"Mirri Elendis"`). Uses
`zo_strformat("<<1>>", name)` in game; strips a trailing `^…` suffix otherwise. Non-strings and `""` are
returned unchanged.

*Since 1.0.0.*

### `LAC.LowerName`

```text
LAC.LowerName(name) -> string | name
```

Lowercases a name with `zo_strlower` (UTF-8 aware) when available, otherwise `string.lower`. Non-strings are
returned unchanged.

*Since 1.0.0.*

### `LAC.NonEmpty`

```text
LAC.NonEmpty(value) -> string | nil
```

Returns `value` when it is a non-empty string, otherwise `nil`. ZOS getters return `""` for "no value"; records
use `nil`.

*Since 1.0.0.*

### `LAC.ClearCache`

```text
LAC.ClearCache()
```

Drops every cache LAC owns (the Collectible caches) and resets the logged-failure dedupe, so failures are
reported again. See [Caching](../guides/caching.md).

*Since 1.0.0.*

### `LAC.CopyList`

```text
LAC.CopyList(list?) -> table
```

Shallow copy of an array (`1..#list`). `nil` returns `{}`.

*Since 1.0.0.*

### `LAC.CopyMap`

```text
LAC.CopyMap(map?) -> table
```

Shallow copy of every key/value pair. `nil` returns `{}`.

*Since 1.0.0.*

## Constants and fields

| Name | Type | Value / meaning |
|---|---|---|
| `LAC.name` | `string` | `"LibApiCompose"` (addon folder and logger tag) |
| `LAC.VERSION` | `string` | Semver of the loaded build, e.g. `"1.0.0"` |
| `LAC.ADDON_VERSION` | `integer` | Encoded version, e.g. `10000` |
| `LAC.NONE` | `string` | `"LAC_NONE"` — sentinel for "explicitly none" in your own lists |
| `LAC.KEY_STRIDE` | `integer` | `16777216` (2^24) — multiplier used by `SlotKey` / `HotbarSlotKey` |
| `LAC.HOTBAR.CATEGORY_PRIMARY` | `HotBarCategory` | `HOTBAR_CATEGORY_PRIMARY` |
| `LAC.HOTBAR.CATEGORY_BACKUP` | `HotBarCategory` | `HOTBAR_CATEGORY_BACKUP` |
| `LAC.HOTBAR.CATEGORY_QUICKSLOT_WHEEL` | `HotBarCategory` | `HOTBAR_CATEGORY_QUICKSLOT_WHEEL` |
| `LAC.HOTBAR.CATEGORY_ALLY_WHEEL` | `HotBarCategory` | `HOTBAR_CATEGORY_ALLY_WHEEL` |
| `LAC.HOTBAR.CATEGORY_EMOTE_WHEEL` | `HotBarCategory` | `HOTBAR_CATEGORY_EMOTE_WHEEL` |
| `LAC.HOTBAR.CATEGORY_MEMENTO_WHEEL` | `HotBarCategory` | `HOTBAR_CATEGORY_MEMENTO_WHEEL` |
| `LAC.HOTBAR.CATEGORY_TOOL_WHEEL` | `HotBarCategory` | `HOTBAR_CATEGORY_TOOL_WHEEL` |
| `LAC.BAGS` | `table` | Bag groups for `BagSlot.ForBags` — see [BagSlot](bagslot.md#constants) |

`LAC._internal` and any name starting with `_` are private and may change in any release
(see [Stability](stability.md)).
