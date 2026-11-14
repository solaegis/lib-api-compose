# ItemLink

`src/ItemLink.lua` — facts derived from an item link alone. Enrichment style C.

## Functions

### `ItemLink.ComposeOnUse`

```text
ItemLink.ComposeOnUse(link, opts?) -> rec | nil
```

Preview of a consumable's on-use ability (potions, food, scrolls…).

| Parameter | Type | Description |
|---|---|---|
| `link` | `string` | An item link. |
| `opts` | `table?` | Reserved. |

**Returns:** a [record](#record), or `nil` when `link` isn't a non-empty string. Items without an on-use ability
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

| Field | Type | ZOS source | Notes |
|---|---|---|---|
| `link` | `string` | argument | identity |
| `icon` | `string?` | `GetItemLinkIcon` | |
| `hasAbility` | `boolean` | `GetItemLinkOnUseAbilityInfo` (1st) | |
| `header` | `string?` | `GetItemLinkOnUseAbilityInfo` (2nd) | |
| `description` | `string?` | `GetItemLinkOnUseAbilityInfo` (3rd) | |
| `cooldown` | `integer?` | `GetItemLinkOnUseAbilityInfo` (4th) | milliseconds |
| `remainingCooldown` | `integer?` | `GetItemLinkOnUseAbilityInfo` (9th) | milliseconds |
