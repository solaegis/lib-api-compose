# Buff

`src/Buff.lua` — active effects on a unit. Enrichment style A over a unit tag.

## Functions

### `Buff.ComposeAll`

```text
Buff.ComposeAll(unitTag?) -> table
```

Every buff and debuff on a unit as an array of [records](#record). `unitTag` defaults to `"player"`. A unit
that doesn't exist returns `{}`.

```lua
local LAC = LibApiCompose
local now = GetFrameTimeSeconds()
for _, buff in ipairs(LAC.Buff.ComposeAll("player")) do
    if not buff.isPermanent then
        d(string.format("%s: %.1fs", buff.name or "?", buff.endTime - now))
    end
end
```

Effects change constantly in combat. React to `EVENT_EFFECT_CHANGED` rather than composing every frame.

*Since 1.0.0.*

### `Buff.Find`

```text
Buff.Find(unitTag?, abilityId) -> rec | nil
```

The first effect on the unit with that ability id, or `nil`. Stops at the first match.

*Since 1.0.0.*

## Record

| Field | Type | ZOS source | Notes |
|---|---|---|---|
| `unitTag` | `string` | argument | identity |
| `index` | `integer` | buff index | valid only until the unit's effects change — don't store it |
| `abilityId` | `integer?` | `GetUnitBuffInfo` (11th) | identity |
| `name` | `string?` | `GetUnitBuffInfo` (1st) + `FormatName` | |
| `icon` | `string?` | `GetUnitBuffInfo` (6th) | |
| `startTime` | `number?` | `GetUnitBuffInfo` (2nd) | seconds, `GetFrameTimeSeconds` clock |
| `endTime` | `number?` | `GetUnitBuffInfo` (3rd) | seconds, `GetFrameTimeSeconds` clock |
| `isPermanent` | `boolean` | | `startTime == endTime` |
| `buffSlot` | `integer?` | `GetUnitBuffInfo` (4th) | pass to `CancelBuff` |
| `stacks` | `integer?` | `GetUnitBuffInfo` (5th) | |
| `effectType` | `BuffEffectType?` | `GetUnitBuffInfo` (8th) | |
| `abilityType` | `AbilityType?` | `GetUnitBuffInfo` (9th) | |
| `statusEffectType` | `StatusEffectType?` | `GetUnitBuffInfo` (10th) | |
| `isDebuff` | `boolean` | | `effectType == BUFF_EFFECT_TYPE_DEBUFF` |
| `canClickOff` | `boolean` | `GetUnitBuffInfo` (12th) | |
| `castByPlayer` | `boolean` | `GetUnitBuffInfo` (13th) | |
