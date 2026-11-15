# Unit

`src/Unit.lua` — a character or NPC by unit tag. Enrichment style F.

## Functions

### `Unit.Compose`

```text
Unit.Compose(unitTag?, opts?) -> rec | nil
```

| Parameter | Type | Description |
|---|---|---|
| `unitTag` | `string?` | `"player"`, `"reticleover"`, `"group1"`, `"companion"`, `"boss1"`, … Default `"player"`. |
| `opts.skipPower` | `boolean?` | Leave out `health`, `magicka` and `stamina` (three fewer calls). Default `false`. |

**Returns:** a [record](#record), or `nil` when the unit doesn't exist (`DoesUnitExist`) or `unitTag` isn't a
string.

```lua
local LAC = LibApiCompose
local target = LAC.Unit.Compose("reticleover", { skipPower = true })
if target and target.isPlayer then
    d(target.name, target.championPoints)
end
```

The record is a snapshot. For values that change many times a second (health in combat) register for the
power-update event instead of composing every frame.

*Since 1.0.0.*

## Record

| Field | Type | ZOS source | Notes |
|---|---|---|---|
| `unitTag` | `string` | argument | identity |
| `name` | `string?` | `GetUnitName` + `FormatName` | character name |
| `displayName` | `string?` | `GetUnitDisplayName` | `@account`; `nil` for NPCs |
| `level` | `integer?` | `GetUnitLevel` | |
| `championPoints` | `integer?` | `GetUnitChampionPoints` | |
| `effectiveChampionPoints` | `integer?` | `GetUnitEffectiveChampionPoints` | capped at the gear cap |
| `classId` | `integer?` | `GetUnitClassId` | |
| `className` | `string?` | `GetUnitClass` + `FormatName` | |
| `raceId` | `integer?` | `GetUnitRaceId` | |
| `raceName` | `string?` | `GetUnitRace` + `FormatName` | |
| `alliance` | `Alliance?` | `GetUnitAlliance` | |
| `allianceName` | `string?` | `GetAllianceName` + `FormatName` | |
| `gender` | `Gender?` | `GetUnitGender` | |
| `zoneName` | `string?` | `GetUnitZone` + `FormatName` | |
| `isPlayer` | `boolean` | `IsUnitPlayer` | a player character, not an NPC |
| `isDead` | `boolean` | `IsUnitDead` | |
| `isInCombat` | `boolean` | `IsUnitInCombat` | |
| `isOnline` | `boolean` | `IsUnitOnline` | |
| `health` | `table?` | `GetUnitPower(tag, COMBAT_MECHANIC_FLAGS_HEALTH)` | `{ current, max, effectiveMax }` |
| `magicka` | `table?` | `GetUnitPower(tag, COMBAT_MECHANIC_FLAGS_MAGICKA)` | `{ current, max, effectiveMax }` |
| `stamina` | `table?` | `GetUnitPower(tag, COMBAT_MECHANIC_FLAGS_STAMINA)` | `{ current, max, effectiveMax }` |
