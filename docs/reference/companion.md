# Companion

`src/Companion.lua` — the summoned companion and the companion roster. Built on [Collectible](collectible.md).

## Functions

### `Companion.ComposeActive`

```text
Companion.ComposeActive(opts?) -> rec | nil
```

| Parameter | Type | Description |
|---|---|---|
| `opts.includePending` | `boolean?` | When no companion is active but one is being summoned, return its record with `isActive = false`, `isPending = true`. Default `false`. |

**Returns:** a [record](#record) for the summoned companion, or `nil` when none is active
(`HasActiveCompanion()` isn't `true`).

The collectible id comes from `GetCompanionCollectibleId(GetActiveCompanionDefId())`, falling back to
`GetActiveCollectibleByType(COLLECTIBLE_CATEGORY_TYPE_COMPANION, GAMEPLAY_ACTOR_CATEGORY_PLAYER)`.

```lua
local LAC = LibApiCompose
local companion = LAC.Companion.ComposeActive()
d(companion and companion.name or "none")
```

*Since 1.0.0.*

### `Companion.ComposeRoster`

```text
Companion.ComposeRoster() -> { list, count, total }
```

Unlocked companions as [Collectible records](collectible.md#record). Same as
`Collectible.ComposeUnlockedByCategory(COLLECTIBLE_CATEGORY_TYPE_COMPANION)`; empty when that constant doesn't
exist.

*Since 1.0.0.*

## Record

| Field | Type | ZOS source | Notes |
|---|---|---|---|
| `defId` | `integer?` | `GetActiveCompanionDefId` / `GetPendingCompanionDefId` | |
| `collectibleId` | `integer?` | `GetCompanionCollectibleId` / `GetActiveCollectibleByType` | identity |
| `id` | `integer?` | | alias of `collectibleId` |
| `name` | `string?` | `Collectible.Compose`, fallback `GetCompanionName` | formatted |
| `icon` | `string?` | `Collectible.Compose` | |
| `isActive` | `boolean` | `HasActiveCompanion` | `false` only for a pending record |
| `isPending` | `boolean` | `HasPendingCompanion` | `true` only with `opts.includePending` |
| `level` | `integer?` | `GetActiveCompanionLevelInfo` (1st) | active companion only |
| `xp` | `integer?` | `GetActiveCompanionLevelInfo` (2nd) | experience into the current level |
| `rapport` | `integer?` | `GetActiveCompanionRapport` | |
| `rapportLevel` | `CompanionRapportLevel?` | `GetActiveCompanionRapportLevel` | |
