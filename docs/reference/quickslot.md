# Quickslot

`src/Quickslot.lua` — the utility wheels: quickslot, ally, emote, memento and tool. Enrichment style E.
For skill bars use [Hotbar](hotbar.md).

## Functions

### `Quickslot.Compose`

```text
Quickslot.Compose(slotIndex, hotbarCategory?) -> rec | nil
```

| Parameter | Type | Description |
|---|---|---|
| `slotIndex` | `integer` | 1-based wheel slot (`1 .. Quickslot.WHEEL_SIZE`). |
| `hotbarCategory` | `HotBarCategory?` | A wheel category from `LAC.HOTBAR`. Default `HOTBAR_CATEGORY_QUICKSLOT_WHEEL`. |

**Returns:** a [record](#record) for every slot, **including empty ones** (check `isEmpty`). `nil` only when
`slotIndex` is `nil`.

For empty slots, `name`, `texture` and `count` are `nil` and `usable` is `false`. For collectible slots, missing
name and icon fall back to the collectible's.

```lua
local LAC = LibApiCompose
local slot = LAC.Quickslot.Compose(1)
if slot and not slot.isEmpty then
    d(slot.name, slot.count)
end
```

*Since 1.0.0.*

### `Quickslot.ComposeWheel`

```text
Quickslot.ComposeWheel(hotbarCategory?) -> { list, count, total }
```

Records for slots `1 .. Quickslot.WHEEL_SIZE` of a utility wheel (default: the quickslot wheel). A category
that isn't a wheel — a skill bar, for example — returns `{ list = {}, count = 0, total = 0 }`.

| Key | Type | Meaning |
|---|---|---|
| `list` | `table` | every slot in order, empty ones included |
| `count` | `integer` | number of non-empty slots |
| `total` | `integer` | `Quickslot.WHEEL_SIZE` |

*Since 1.0.0.*

### `Quickslot.IsWheel`

```text
Quickslot.IsWheel(hotbarCategory) -> boolean
```

True for the quickslot, ally, emote, memento and tool wheel categories.

*Since 1.0.0.*

### `Quickslot.Args`

```text
Quickslot.Args(rec?) -> slotIndex, hotbarCategory
```

Unpacks a record for slot APIs: `GetSlotCooldownInfo(LAC.Quickslot.Args(rec))`. Returns `nil, nil` for `nil`.

*Since 1.0.0.*

### `Quickslot.ActionArgs`

```text
Quickslot.ActionArgs(rec?) -> actionType, actionId
```

Unpacks what the slot holds. Returns `nil, nil` for `nil`.

*Since 1.0.0.*

## Record

| Field | Type | ZOS source | Notes |
|---|---|---|---|
| `hotbarCategory` | `HotBarCategory` | argument | identity |
| `slotIndex` | `integer` | argument | identity |
| `actionType` | `ActionBarSlotType?` | `GetSlotType` | identity |
| `actionId` | `integer?` | `GetSlotBoundId` | identity; item id, collectible id, … |
| `isEmpty` | `boolean` | | no type, `ACTION_TYPE_NOTHING`, or id `0` |
| `isCurrent` | `boolean` | `GetCurrentQuickslot` | the slot the quickslot key uses; always `false` on other wheels |
| `name` | `string?` | `GetSlotName` + `FormatName` | collectible fallback |
| `texture` | `string?` | `GetSlotTexture` | |
| `icon` | `string?` | `texture`, else collectible icon | prefer this for display |
| `count` | `integer?` | `GetSlotItemCount` | |
| `usable` | `boolean` | `IsSlotUsable` | |
| `itemLink` | `string?` | `GetSlotItemLink` | item slots only |
| `cooldownRemaining` | `integer?` | `GetSlotCooldownInfo` (1st) | milliseconds |
| `cooldownDuration` | `integer?` | `GetSlotCooldownInfo` (2nd) | milliseconds |
| `collectibleCategory` | `CollectibleCategoryType?` | `Collectible.Compose` | collectible slots only |

## Constants

| Name | Value | Meaning |
|---|---|---|
| `Quickslot.WHEEL_SIZE` | `ACTION_BAR_UTILITY_BAR_SIZE` or `8` | slots on each utility wheel |
