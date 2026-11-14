# API reference

Every public function and constant, grouped by module. All modules hang off the `LibApiCompose` global:

```lua
local LAC = LibApiCompose
local slot = LAC.BagSlot.Compose(BAG_BACKPACK, 0)
```

## Conventions

**Signatures** use this notation:

```text
Module.Function(required, optional?, opts?) -> returnType
```

| Notation | Meaning |
|---|---|
| `name?` | optional argument; may be `nil` |
| `opts?` | optional options table; unknown keys ignored |
| `T \| nil` | returns `T`, or `nil` when the handle is empty or invalid |
| `rec` | a compose record — a fresh table you own (see [Core concepts](../guides/concepts.md#records)) |
| `{ list, count, total }` | aggregate result — see [Lists](../guides/concepts.md#lists) |

**Types** use ESO/Lua names: `integer`, `number`, `string`, `boolean`, `function`, `table`, `id64`
(ZOS 64-bit id userdata), and ZOS enums such as `Bag`, `ItemType`, `HotBarCategory`, `ActionBarSlotType`.

**Field tables** list each record field with its type, the ZOS API it comes from, and notes. A field whose API
is missing on the running client is `nil` (or `false` for booleans).

**Since** marks the first version a function or field appeared in. Everything currently documented is
`1.0.0`.

## Function index

| Function | Summary |
|---|---|
| [`LAC.SafeCall`](core.md#lacsafecall) | Protected call, first return value or `nil` |
| [`LAC.SafeCallMulti`](core.md#lacsafecallmulti) | Protected call, `ok` plus every return value |
| [`LAC.DebugPrint`](core.md#lacdebugprint) | Log to LibDebugLogger when installed |
| [`LAC.AtLeast`](core.md#lacatleast) | Runtime library version check |
| [`LAC.SlotKey`](core.md#lacslotkey) | Numeric key for bag + slot |
| [`LAC.HotbarSlotKey`](core.md#lachotbarslotkey) | Numeric key for hotbar + slot |
| [`LAC.FormatName`](core.md#lacformatname) | Strip ZOS grammar suffixes from a name |
| [`LAC.LowerName`](core.md#laclowername) | Locale-aware lowercase |
| [`LAC.ClearCache`](core.md#lacclearcache) | Drop every LAC cache |
| [`LAC.CopyList`](core.md#laccopylist) / [`LAC.CopyMap`](core.md#laccopymap) | Shallow copies |
| [`Iterate.ForIndex`](iterate.md#iterateforindex) / [`MapIndex`](iterate.md#iteratemapindex) | Flat index walks |
| [`Iterate.NestedFor`](iterate.md#iteratenestedfor) / [`NestedMap`](iterate.md#iteratenestedmap) | Nested index walks |
| [`Iterate.ForLinked`](iterate.md#iterateforlinked) | Linked-id walk |
| [`BagSlot.Compose`](bagslot.md#bagslotcompose) | Bag slot → item record |
| [`BagSlot.ForBag`](bagslot.md#bagslotforbag) / [`MapBag`](bagslot.md#bagslotmapbag) | Walk a bag |
| [`BagSlot.ComposeWorn`](bagslot.md#bagslotcomposeworn) | Equipped items |
| [`BagSlot.Args`](bagslot.md#bagslotargs) | `bagId, slotIndex` from a record |
| [`Gear.ComposeFromSlot`](gear.md#gearcomposefromslot) | Item record + set, trait, enchant, junk facts |
| [`Collectible.Compose`](collectible.md#collectiblecompose) | Collectible id → record |
| [`Collectible.ComposeUnlockedByCategory`](collectible.md#collectiblecomposeunlockedbycategory) | Unlocked collectibles of a category |
| [`Collectible.IndexByName`](collectible.md#collectibleindexbyname) | Lowercase name → id map |
| [`Collectible.ClearCache`](collectible.md#collectibleclearcache) / [`InvalidateLists`](collectible.md#collectibleinvalidatelists) | Cache control |
| [`Quickslot.Compose`](quickslot.md#quickslotcompose) | Hotbar slot → record |
| [`Quickslot.ComposeWheel`](quickslot.md#quickslotcomposewheel) | Every quickslot wheel slot |
| [`Quickslot.Args`](quickslot.md#quickslotargs) / [`ActionArgs`](quickslot.md#quickslotactionargs) | Unpack a record |
| [`ItemLink.ComposeOnUse`](itemlink.md#itemlinkcomposeonuse) | Item link → on-use ability preview |
| [`Companion.ComposeActive`](companion.md#companioncomposeactive) | Summoned companion |
| [`Companion.ComposeRoster`](companion.md#companioncomposeroster) | Unlocked companions |

Record shapes for every module are collected on [Record schemas](records.md).
