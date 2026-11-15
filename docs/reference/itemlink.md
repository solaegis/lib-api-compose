# ItemLink

`src/ItemLink.lua` — facts derived from an item link alone. Enrichment style C.

## Functions

### `ItemLink.Compose`

```text
ItemLink.Compose(link, opts?) -> rec | nil
```

Item facts from a link — for loot, mail, guild store and chat, where there is no bag slot. When you do have a
slot, [`BagSlot.Compose`](bagslot.md#bagslotcompose) returns more.

| Parameter | Type | Description |
|---|---|---|
| `link` | `string` | An item link. |
| `opts.includeName` | `boolean?` | Also fetch the formatted item name. Default `false`. |

**Returns:** an [item record](#record), or `nil` when `link` is empty or not an item link.

```lua
local LAC = LibApiCompose
local item = LAC.ItemLink.Compose("|H1:item:45061:363:50:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h", { includeName = true })
if item and not item.isBound then
    d(item.name, item.sellValue)
end
```

For set, trait and enchant facts use [`Gear.ComposeFromLink`](gear.md#gearcomposefromlink).

*Since 1.0.0.*

### `ItemLink.ParseId`

```text
ItemLink.ParseId(link) -> integer | nil
```

The item id embedded in an item link, parsed from the string without calling the game. `nil` for anything that
isn't an item link.

*Since 1.0.0.*

### `ItemLink.ComposeOnUse`

```text
ItemLink.ComposeOnUse(link) -> rec | nil
```

Preview of a consumable's on-use ability (potions, food, scrolls…).

| Parameter | Type | Description |
|---|---|---|
| `link` | `string` | An item link. |

**Returns:** an [on-use record](#on-use-record), or `nil` when `link` isn't a non-empty string. Items without an on-use ability
return a record with `hasAbility = false`.

```lua
local LAC = LibApiCompose
local slot = LAC.BagSlot.Compose(BAG_BACKPACK, 0)
local onUse = slot and LAC.ItemLink.ComposeOnUse(slot.link)
if onUse and onUse.hasAbility then
    d(onUse.header, onUse.description)
end
```

*Since 1.0.0.*

## Record

From `ItemLink.Compose`.

| Field | Type | ZOS source | Notes |
|---|---|---|---|
| `link` | `string` | argument | identity |
| `id` | `integer` | `GetItemLinkItemId` | identity |
| `name` | `string?` | `GetItemLinkName` + `FormatName` | only with `opts.includeName` |
| `type` | `ItemType?` | `GetItemLinkItemType` (1st) | |
| `specializedType` | `SpecializedItemType?` | `GetItemLinkItemType` (2nd) | |
| `functionalQuality` | `ItemQuality?` | `GetItemLinkFunctionalQuality` | |
| `displayQuality` | `ItemDisplayQuality?` | `GetItemLinkDisplayQuality` | |
| `icon` | `string?` | `GetItemLinkInfo` (1st) | |
| `sellValue` | `integer?` | `GetItemLinkInfo` (2nd) | |
| `meetsUsageRequirement` | `boolean?` | `GetItemLinkInfo` (3rd) | |
| `equipType` | `EquipType?` | `GetItemLinkInfo` (4th) | |
| `itemStyleId` | `integer?` | `GetItemLinkInfo` (5th) | |
| `requiredLevel` | `integer?` | `GetItemLinkRequiredLevel` | |
| `requiredCP` | `integer?` | `GetItemLinkRequiredChampionPoints` | |
| `bindType` | `BindType?` | `GetItemLinkBindType` | |
| `isBound` | `boolean` | `IsItemLinkBound` | |
| `isStolen` | `boolean` | `IsItemLinkStolen` | |
| `isCrafted` | `boolean` | `IsItemLinkCrafted` | |
| `isUnique` | `boolean` | `IsItemLinkUnique` | |
| `isCompanion` | `boolean` | `GetItemLinkActorCategory` | |
| `isGear` | `boolean` | item type | weapon or armor (jewelry is armor) |
| `isGlyph` | `boolean` | item type | |
| `isSetCollectionPiece` | `boolean` | `IsItemLinkSetCollectionPiece` | |
| `isSetCollectionUnlocked` | `boolean` | `IsItemSetCollectionPieceUnlocked` | |

A link carries no location: there are no `bagId`, `slotIndex`, `stack`, lock or junk fields.

## On-use record

From `ItemLink.ComposeOnUse`.

| Field | Type | ZOS source | Notes |
|---|---|---|---|
| `link` | `string` | argument | identity |
| `icon` | `string?` | `GetItemLinkIcon` | |
| `hasAbility` | `boolean` | `GetItemLinkOnUseAbilityInfo` (1st) | |
| `header` | `string?` | `GetItemLinkOnUseAbilityInfo` (2nd) | |
| `description` | `string?` | `GetItemLinkOnUseAbilityInfo` (3rd) | |
| `cooldown` | `integer?` | `GetItemLinkOnUseAbilityInfo` (4th) | milliseconds |
| `hasScaling` | `boolean` | `GetItemLinkOnUseAbilityInfo` (5th) | effect scales with level |
| `minLevel` | `integer?` | `GetItemLinkOnUseAbilityInfo` (6th) | |
| `maxLevel` | `integer?` | `GetItemLinkOnUseAbilityInfo` (7th) | |
| `isChampionPoints` | `boolean` | `GetItemLinkOnUseAbilityInfo` (8th) | the level range is in champion points |
| `remainingCooldown` | `integer?` | `GetItemLinkOnUseAbilityInfo` (9th) | milliseconds |
