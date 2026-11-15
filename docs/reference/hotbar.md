# Hotbar

`src/Hotbar.lua` — skill bar slots. Enrichment style E. For the utility wheels use [Quickslot](quickslot.md).

## Functions

### `Hotbar.ComposeSlot`

```text
Hotbar.ComposeSlot(slotIndex, hotbarCategory?) -> rec | nil
```

| Parameter | Type | Description |
|---|---|---|
| `slotIndex` | `integer` | Action slot index: `Hotbar.FIRST_SLOT .. Hotbar.ULTIMATE_SLOT` (`3..8`). |
| `hotbarCategory` | `HotBarCategory?` | `HOTBAR_CATEGORY_PRIMARY`, `HOTBAR_CATEGORY_BACKUP`, … Default: the active bar (`GetActiveHotbarCategory`). |

**Returns:** a [record](#record) for every slot, **including empty ones** (check `isEmpty`). `nil` only when
`slotIndex` is `nil`.

*Since 1.0.0.*

### `Hotbar.ComposeBar`

```text
Hotbar.ComposeBar(hotbarCategory?) -> { list, count, total }
```

Records for the five ability slots and the ultimate, in order.

| Key | Type | Meaning |
|---|---|---|
| `list` | `table` | every slot in order, empty ones included |
| `count` | `integer` | number of non-empty slots |
| `total` | `integer` | slots on the bar (`6`) |

```lua
local LAC = LibApiCompose
for _, slot in ipairs(LAC.Hotbar.ComposeBar(HOTBAR_CATEGORY_BACKUP).list) do
    if not slot.isEmpty then
        d(slot.slotIndex, slot.name, slot.abilityId)
    end
end
```

*Since 1.0.0.*

## Record

| Field | Type | ZOS source | Notes |
|---|---|---|---|
| `hotbarCategory` | `HotBarCategory` | argument | identity |
| `slotIndex` | `integer` | argument | identity |
| `actionType` | `ActionBarSlotType?` | `GetSlotType` | identity |
| `actionId` | `integer?` | `GetSlotBoundId` | identity; ability id or crafted ability id |
| `isEmpty` | `boolean` | | no type, `ACTION_TYPE_NOTHING`, or id `0` |
| `isUltimate` | `boolean` | slot index | `slotIndex == Hotbar.ULTIMATE_SLOT` |
| `abilityId` | `integer?` | `actionId`, or `GetAbilityIdForCraftedAbilityId` | the castable ability, also for scribed skills |
| `craftedAbilityId` | `integer?` | `actionId` | scribed skills (`ACTION_TYPE_CRAFTED_ABILITY`) only |
| `name` | `string?` | `GetSlotName` + `FormatName` | |
| `icon` | `string?` | `GetSlotTexture` | |
| `usable` | `boolean` | `IsSlotUsable` | |
| `cooldownRemaining` | `integer?` | `GetSlotCooldownInfo` (1st) | milliseconds |
| `cooldownDuration` | `integer?` | `GetSlotCooldownInfo` (2nd) | milliseconds |

## Constants

| Name | Value | Meaning |
|---|---|---|
| `Hotbar.FIRST_SLOT` | `ACTION_BAR_FIRST_NORMAL_SLOT_INDEX + 1` (`3`) | first ability slot |
| `Hotbar.LAST_SLOT` | `Hotbar.ULTIMATE_SLOT - 1` (`7`) | last ability slot |
| `Hotbar.ULTIMATE_SLOT` | `ACTION_BAR_ULTIMATE_SLOT_INDEX + 1` (`8`) | ultimate slot |
