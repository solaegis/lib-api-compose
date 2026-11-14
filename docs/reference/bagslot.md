# BagSlot

`src/BagSlot.lua` — inventory items by bag and slot, plus bag walkers. Enrichment styles D (slot compose),
A (index walk) and G (aggregate).

## Functions

### `BagSlot.Compose`

```text
BagSlot.Compose(bagId, slotIndex, opts?) -> rec | nil
```

Snapshot of the item in one bag slot.

| Parameter | Type | Description |
|---|---|---|
| `bagId` | `Bag` | `BAG_BACKPACK`, `BAG_BANK`, `BAG_WORN`, `BAG_VIRTUAL`, … |
| `slotIndex` | `integer` | 0-based slot. For `BAG_VIRTUAL` it is the item id. |
| `opts.includeName` | `boolean?` | Also fetch the formatted item name. Default `false`. |

**Returns:** a [record](#record), or `nil` when `bagId`/`slotIndex` is `nil`, the slot is empty
(`GetItemId <= 0`), or the item has no link.

```lua
local LAC = LibApiCompose
local slot = LAC.BagSlot.Compose(BAG_BACKPACK, 0, { includeName = true })
if slot then
    d(slot.name, slot.stack, slot.isBound)
end
```

*Since 1.0.0.*

### `BagSlot.ForBag`

```text
BagSlot.ForBag(bagId, fn, opts?) -> integer
```

Calls `fn(rec)` with a fresh `Compose` record for every occupied slot.

| Parameter | Type | Description |
|---|---|---|
| `bagId` | `Bag` | Bag to walk. `BAG_VIRTUAL` is walked with `GetNextVirtualBagSlotId`; other bags `0 .. GetBagSize - 1`. |
| `fn` | `function` | `fn(rec)`. Return `true` to stop the walk. |
| `opts` | `table?` | Passed to `Compose`. |

**Returns:** number of records visited (including the one that stopped the walk). `0` when `bagId` or `fn` is
`nil`.

*Since 1.0.0.*

### `BagSlot.MapBag`

```text
BagSlot.MapBag(bagId, mapFn?, opts?) -> table
```

Collects non-`nil` results of `mapFn(rec)` for every occupied slot, or the records themselves when `mapFn` is
`nil`.

```lua
local LAC = LibApiCompose
local locked = LAC.BagSlot.MapBag(BAG_BACKPACK, function(slot)
    return slot.isLocked and slot.link or nil
end)
```

*Since 1.0.0.*

### `BagSlot.ComposeWorn`

```text
BagSlot.ComposeWorn(opts?) -> table
```

Records for every equipped item (`BAG_WORN`), each with two extra fields:

| Field | Type | Source | Notes |
|---|---|---|---|
| `equipSlot` | `EquipSlot` | slot index | Same as `slotIndex` |
| `equipSlotName` | `string?` | `GetString("SI_EQUIPSLOT", slot)` | Localised slot name |

**Returns:** array of records; `{}` when `BAG_WORN` isn't defined.

*Since 1.0.0.*

### `BagSlot.Args`

```text
BagSlot.Args(rec?) -> bagId, slotIndex
```

Unpacks a record's identity for ZOS calls: `UseItem(LAC.BagSlot.Args(rec))`. Returns `nil, nil` for `nil`.

*Since 1.0.0.*

## Record

| Field | Type | ZOS source | Notes |
|---|---|---|---|
| `bagId` | `Bag` | argument | identity |
| `slotIndex` | `integer` | argument | identity |
| `id` | `integer` | `GetItemId` | item id (shared by identical items) |
| `link` | `string` | `GetItemLink(bag, slot, LINK_STYLE_DEFAULT)` | identity |
| `uniqueId` | `id64?` | `GetItemUniqueId` | stable across moves; userdata |
| `uniqueIdString` | `string?` | `Id64ToString(uniqueId)` | use for SavedVariables keys |
| `name` | `string?` | `GetItemName` + `FormatName` | only with `opts.includeName` |
| `type` | `ItemType?` | `GetItemType` | |
| `functionalQuality` | `ItemQuality?` | `GetItemFunctionalQuality` (fallback `GetItemQuality`) | |
| `displayQuality` | `ItemDisplayQuality?` | `GetItemInfo` (fallback `GetItemDisplayQuality`) | |
| `stack` | `integer` | `GetSlotStackSize` | `1` if unreadable |
| `maxStack` | `integer?` | `GetSlotStackSize` (2nd return) | |
| `icon` | `string?` | `GetItemInfo` | texture path |
| `sellValue` | `integer?` | `GetItemInfo` | per item, to a merchant |
| `equipType` | `EquipType?` | `GetItemInfo` | |
| `meetsUsageRequirement` | `boolean?` | `GetItemInfo` | |
| `requiredLevel` | `integer?` | `GetItemRequiredLevel` | |
| `requiredCP` | `integer?` | `GetItemRequiredChampionPoints` | |
| `isCompanion` | `boolean` | `GetItemActorCategory` | companion gear |
| `isGear` | `boolean` | item type | weapon or armor (jewelry is armor) |
| `isGlyph` | `boolean` | item type | armor, weapon or jewelry glyph |
| `isLocked` | `boolean` | `GetItemInfo` (fallback `IsItemPlayerLocked`) | player lock |
| `isJunk` | `boolean` | `IsItemJunk` | |
| `isBound` | `boolean` | `IsItemBound` | |
| `isStolen` | `boolean` | `IsItemStolen` | |
