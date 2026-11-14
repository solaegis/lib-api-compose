# Gear

`src/Gear.lua` — gear triage facts layered on a BagSlot record. Enrichment style D.

## Functions

### `Gear.ComposeFromSlot`

```text
Gear.ComposeFromSlot(bagId, slotIndex, opts?) -> rec | nil
```

A [BagSlot record](bagslot.md#record) plus set, trait, enchant and junk facts.

| Parameter | Type | Description |
|---|---|---|
| `bagId` | `Bag` | |
| `slotIndex` | `integer` | 0-based slot |
| `opts.equippedSetCounts` | `boolean?` | Count set pieces as worn (`GetItemLinkSetInfo(link, true)`). Use for `BAG_WORN`. Default `false`. |
| `opts.includeName` | `boolean?` | Passed to `BagSlot.Compose`. |

**Returns:** the record, or `nil` for an empty slot.

For items that aren't gear (`isGear == false`) the record has the same shape with empty values, and the set,
trait and enchant APIs aren't called.

```lua
local LAC = LibApiCompose
local gear = LAC.Gear.ComposeFromSlot(BAG_WORN, EQUIP_SLOT_CHEST, { equippedSetCounts = true })
if gear and gear.hasSet then
    d(string.format("%s %d/%d", gear.set.name, gear.set.count, gear.set.max))
end
```

*Since 1.0.0.*

## Record

Every [BagSlot field](bagslot.md#record), plus:

| Field | Type | ZOS source | Notes |
|---|---|---|---|
| `hasSet` | `boolean` | `GetItemLinkSetInfo` | |
| `set.hasSet` | `boolean` | | same as `hasSet` |
| `set.id` | `integer?` | `GetItemLinkSetInfo` (6th) | |
| `set.name` | `string?` | `GetItemLinkSetInfo` (2nd) + `FormatName` | |
| `set.count` | `integer?` | `GetItemLinkSetInfo` (4th) | normal pieces equipped |
| `set.perfectedCount` | `integer?` | `GetItemLinkSetInfo` (7th) | perfected pieces equipped |
| `set.max` | `integer?` | `GetItemLinkSetInfo` (5th) | |
| `traitType` | `ItemTraitType?` | `GetItemLinkTraitType` (fallback `GetItemTrait`) | `nil` for non-gear |
| `trait.id` | `ItemTraitType?` | | same as `traitType` |
| `trait.name` | `string?` | `GetString("SI_ITEMTRAITTYPE", trait)` | `nil` for no trait |
| `isIntricate` | `boolean` | trait type | weapon, armor or jewelry intricate |
| `isResearchable` | `boolean` | `CanItemLinkBeTraitResearched` | trait not yet known |
| `canMarkJunk` | `boolean` | `CanItemBeMarkedAsJunk` | `true` even if already junk; see `isJunk`. Without the API: not companion and not locked. |
| `enchant.hasEnchant` | `boolean` | `GetItemLinkEnchantInfo` | judged by header/description text, so jewelry counts |
| `enchant.hasCharges` | `boolean` | `GetItemLinkEnchantInfo` (1st) | weapons only |
| `enchant.name` | `string?` | `GetItemLinkEnchantInfo` (2nd) | header, e.g. "Maximum Health Enchantment" |
| `enchant.description` | `string?` | `GetItemLinkEnchantInfo` (3rd) | |
