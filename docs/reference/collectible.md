# Collectible

`src/Collectible.lua` — collectibles by id and by category. Enrichment styles C (id lookup) and G (aggregate).
This is the only module with caches; see [Caching](../guides/caching.md).

## Functions

### `Collectible.Compose`

```text
Collectible.Compose(collectibleId, opts?) -> rec | nil
```

| Parameter | Type | Description |
|---|---|---|
| `collectibleId` | `integer \| string` | Converted with `tonumber`. |
| `opts.skipCache` | `boolean?` | Re-read name, icon and category instead of using (and filling) the per-id cache. |

**Returns:** a [record](#record), or `nil` when the id isn't a positive number.

Name, icon and category are cached per id. `unlocked`, `active` and `nickname` are read live on every call.

```lua
local LAC = LibApiCompose
local pet = LAC.Collectible.Compose(5)
if pet and pet.unlocked and not pet.active then
    UseCollectible(pet.id)
end
```

*Since 1.0.0.*

### `Collectible.ComposeUnlockedByCategory`

```text
Collectible.ComposeUnlockedByCategory(categoryType) -> { list, count, total }
```

Every unlocked collectible in a category, as fresh records.

| Parameter | Type | Description |
|---|---|---|
| `categoryType` | `CollectibleCategoryType` | e.g. `COLLECTIBLE_CATEGORY_TYPE_MOUNT` |

**Returns:**

| Key | Type | Meaning |
|---|---|---|
| `list` | `table` | records in category order |
| `count` | `integer` | `#list` |
| `total` | `integer` | all collectibles in the category, locked or not |

`nil` category returns `{ list = {}, count = 0, total = 0 }`. The unlocked-id list is cached per category and
cleared by collection events.

*Since 1.0.0.*

### `Collectible.IndexByName`

```text
Collectible.IndexByName(categoryType) -> table
```

Map of lowercased, formatted name → collectible id for **every** collectible in the category (locked or not).
On duplicate names the first id wins. Intended for resolving user-typed names; prefer ids everywhere else.

**Returns:** a fresh map (`{}` for a `nil` category). Cached per category and cleared by collection events.

```lua
local LAC = LibApiCompose
local id = LAC.Collectible.IndexByName(COLLECTIBLE_CATEGORY_TYPE_MOUNT)[LAC.LowerName("Bay Dun Horse")]
```

*Since 1.0.0.*

### `Collectible.ClearCache`

```text
Collectible.ClearCache()
```

Drops the per-id static facts, category lists and name indexes. `LAC.ClearCache()` calls this.

*Since 1.0.0.*

### `Collectible.InvalidateLists`

```text
Collectible.InvalidateLists()
```

Drops category lists and name indexes but keeps per-id static facts. Registered as the handler for the
collection events listed in [Caching](../guides/caching.md#self-invalidation).

*Since 1.0.0.*

## Record

| Field | Type | ZOS source | Cached | Notes |
|---|---|---|---|---|
| `id` | `integer` | argument | — | identity |
| `name` | `string?` | `GetCollectibleName` (fallback `GetCollectibleInfo`) + `FormatName` | yes | |
| `nickname` | `string?` | `GetCollectibleNickname` + `FormatName` | no | `nil` when empty |
| `icon` | `string?` | `GetCollectibleIcon` | yes | |
| `category` | `CollectibleCategoryType?` | `GetCollectibleCategoryType` | yes | |
| `unlocked` | `boolean` | `IsCollectibleUnlocked` | no | |
| `active` | `boolean` | `IsCollectibleActive(id, GAMEPLAY_ACTOR_CATEGORY_PLAYER)` | no | |

## Events registered

LAC registers `Collectible.InvalidateLists` under the namespace `LibApiCompose_Collectible` for each of these
that exists on the client: `EVENT_COLLECTION_UPDATED`, `EVENT_COLLECTIBLES_UNLOCK_STATE_CHANGED`,
`EVENT_COLLECTIBLE_UPDATED`, `EVENT_COLLECTIBLES_UPDATED`.
