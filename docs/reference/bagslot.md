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
| `opts.includeCreator` | `boolean?` | Also fetch the crafter's name. Default `false`. |

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
| `bagId` | `Bag` | Bag to walk. `BAG_VIRTUAL` and `BAG_GUILDBANK` are walked with their "next slot id" APIs; other bags `0 .. GetBagSize - 1`. |
| `fn` | `function` | `fn(rec)`. Return `true` to stop the walk. |
| `opts.filter` | `function?` | `filter(bagId, slotIndex, itemType)`; return `false` to skip a slot **before** it is composed. Use it to keep large walks cheap. |
| `opts` | `table?` | Other keys are passed to `Compose`. |

The guild bank only has data while it is open and loaded (after `EVENT_GUILD_BANK_ITEMS_READY`).

**Returns:** number of records visited (including the one that stopped the walk). `0` when `bagId` or `fn` is
`nil`.

*Since 1.0.0.*

### `BagSlot.ForBags`

```text
BagSlot.ForBags(bagIds, fn, opts?) -> integer
```

`ForBag` over a list of bags, in order. Returning `true` from `fn` stops the whole walk.

| Parameter | Type | Description |
|---|---|---|
| `bagIds` | `table` | Array of bags, e.g. `LAC.BAGS.BANK` or `{ BAG_BACKPACK, BAG_BANK }`. |

**Returns:** total records visited.

```lua
local LAC = LibApiCompose
local banked = 0
LAC.BagSlot.ForBags(LAC.BAGS.BANK, function(slot)
    banked = banked + slot.stack
end)
```

*Since 1.0.0.*

### `BagSlot.MapBag`

```text
BagSlot.MapBag(bagId, mapFn?, opts?) -> table
```

Collects non-`nil` results of `mapFn(rec)` for every occupied slot, or the records themselves when `mapFn` is
`nil`. `bagId` may be one bag or a list of bags.

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

Records for every equipped item (`BAG_WORN`, or the active companion's `BAG_COMPANION_WORN` with
`opts.companion = true`), each with two extra fields:

| Field | Type | Source | Notes |
|---|---|---|---|
| `equipSlot` | `EquipSlot` | slot index | Same as `slotIndex` |
| `equipSlotName` | `string?` | `GetString("SI_EQUIPSLOT", slot)` | Localised slot name |

**Returns:** array of records; `{}` when the bag constant isn't defined.

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
| `creatorName` | `string?` | `GetItemCreatorName` | only with `opts.includeCreator`; `nil` when not crafted |
| `type` | `ItemType?` | `GetItemType` (1st) | |
| `specializedType` | `SpecializedItemType?` | `GetItemType` (2nd) | |
| `functionalQuality` | `ItemQuality?` | `GetItemInfo` (8th), fallback `GetItemFunctionalQuality` | |
| `displayQuality` | `ItemDisplayQuality?` | `GetItemInfo` (9th), fallback `GetItemDisplayQuality` | colour shown in the UI |
| `stack` | `integer` | `GetSlotStackSize` | `1` if unreadable |
| `maxStack` | `integer?` | `GetSlotStackSize` (2nd) | |
| `icon` | `string?` | `GetItemInfo` | texture path |
| `sellValue` | `integer?` | `GetItemInfo` | per item, to a merchant |
| `equipType` | `EquipType?` | `GetItemInfo` | |
| `itemStyleId` | `integer?` | `GetItemInfo` (7th) | |
| `meetsUsageRequirement` | `boolean?` | `GetItemInfo` | |
| `requiredLevel` | `integer?` | `GetItemRequiredLevel` | |
| `requiredCP` | `integer?` | `GetItemRequiredChampionPoints` | |
| `bindType` | `BindType?` | `GetItemBindType` | how it binds; see `isBound` for whether it has |
| `condition` | `integer?` | `GetItemCondition` | gear only (0–100) |
| `isCompanion` | `boolean` | `GetItemActorCategory` | companion gear |
| `isGear` | `boolean` | item type | weapon or armor (jewelry is armor) |
| `isGlyph` | `boolean` | item type | armor, weapon or jewelry glyph |
| `isPlayerLocked` | `boolean` | `IsItemPlayerLocked` | the lock the player toggles in the inventory |
| `isSlotLocked` | `boolean` | `GetItemInfo` (5th) | transient: pending trade, mail attachment, in use |
| `isLocked` | `boolean` | | `isPlayerLocked or isSlotLocked` — check this before any destructive action |
| `isJunk` | `boolean` | `IsItemJunk` | |
| `isBound` | `boolean` | `IsItemBound` | |
| `isStolen` | `boolean` | `IsItemStolen` | |
| `isUnique` | `boolean` | `IsItemLinkUnique` | |
| `isInArmory` | `boolean` | `IsItemInArmory` | part of a saved armory build |
| `isUsable` | `boolean` | `IsItemUsable` (1st) | |
| `isSetCollectionPiece` | `boolean` | `IsItemLinkSetCollectionPiece` | |
| `isSetCollectionUnlocked` | `boolean` | `IsItemSetCollectionPieceUnlocked` | `false` when not a set-collection piece |

## Constants

| Name | Value | Meaning |
|---|---|---|
| `LAC.BAGS.BANK` | `{ BAG_BANK, BAG_SUBSCRIBER_BANK }` | The personal bank is two bags; walk both |
| `LAC.BAGS.HOUSE_BANKS` | `{ BAG_HOUSE_BANK_ONE … TEN }` | Storage coffers and chests |

Lists contain only the constants that exist on the running client. Copy before modifying.
