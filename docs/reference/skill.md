# Skill

`src/Skill.lua` — skill lines and their abilities. Enrichment styles B (nested index) and G (aggregate).

Indices are the game's own: `skillType` (`SKILL_TYPE_CLASS`, `SKILL_TYPE_WEAPON`, …), `lineIndex` and
`abilityIndex`, all 1-based. Nothing is cached — rank, purchase and morph state change during play.

## Functions

### `Skill.ComposeLine`

```text
Skill.ComposeLine(skillType, lineIndex) -> rec | nil
```

**Returns:** a [line record](#line-record), or `nil` when the line doesn't exist.

*Since 1.0.0.*

### `Skill.ComposeAbility`

```text
Skill.ComposeAbility(skillType, lineIndex, abilityIndex) -> rec | nil
```

**Returns:** an [ability record](#ability-record), or `nil` when the ability doesn't exist.

*Since 1.0.0.*

### `Skill.ComposeLines`

```text
Skill.ComposeLines(skillType?) -> table
```

Array of line records for one skill type, or for every type when `skillType` is `nil`.

```lua
local LAC = LibApiCompose
for _, line in ipairs(LAC.Skill.ComposeLines(SKILL_TYPE_WEAPON)) do
    d(line.name, line.rank)
end
```

*Since 1.0.0.*

### `Skill.ComposeAbilities`

```text
Skill.ComposeAbilities(skillType, lineIndex) -> table
```

Array of ability records for one line; `{}` when either argument is `nil`.

*Since 1.0.0.*

### `Skill.ForEachAbility`

```text
Skill.ForEachAbility(fn)
```

Calls `fn(abilityRec)` for every ability of every line. Return `true` to stop. This is several thousand game
calls — run it on demand (a slash command, a UI opening), never per frame.

```lua
local LAC = LibApiCompose
local unspent = {}
LAC.Skill.ForEachAbility(function(ability)
    if ability.isPassive and not ability.isPurchased then
        unspent[#unspent + 1] = ability.name
    end
end)
```

*Since 1.0.0.*

## Line record

| Field | Type | ZOS source | Notes |
|---|---|---|---|
| `skillType` | `SkillType` | argument | identity |
| `lineIndex` | `integer` | argument | identity; position can differ between characters |
| `id` | `integer` | `GetSkillLineId` | identity; stable across characters |
| `name` | `string?` | `GetSkillLineNameById` + `FormatName` | |
| `rank` | `integer?` | `GetSkillLineDynamicInfo` (1st) | |
| `isAdvised` | `boolean` | `GetSkillLineDynamicInfo` (2nd) | |
| `isActive` | `boolean` | `GetSkillLineDynamicInfo` (3rd) | |
| `isDiscovered` | `boolean` | `GetSkillLineDynamicInfo` (4th) | |
| `xp` | `table?` | `GetSkillLineXPInfo` | `{ last, next, current }` |

## Ability record

| Field | Type | ZOS source | Notes |
|---|---|---|---|
| `skillType` | `SkillType` | argument | identity |
| `lineIndex` | `integer` | argument | identity |
| `abilityIndex` | `integer` | argument | identity |
| `abilityId` | `integer?` | `GetSkillAbilityId(…, false)` | current morph / passive rank |
| `name` | `string` | `GetSkillAbilityInfo` (1st) + `FormatName` | |
| `icon` | `string?` | `GetSkillAbilityInfo` (2nd) | |
| `earnedRank` | `integer?` | `GetSkillAbilityInfo` (3rd) | line rank that unlocks it |
| `isPassive` | `boolean` | `GetSkillAbilityInfo` (4th) | |
| `isUltimate` | `boolean` | `GetSkillAbilityInfo` (5th) | |
| `isPurchased` | `boolean` | `GetSkillAbilityInfo` (6th) | |
| `progressionIndex` | `integer?` | `GetSkillAbilityInfo` (7th) | `nil` for passives |
| `rank` | `integer?` | `GetSkillAbilityInfo` (8th) | |
| `isCrafted` | `boolean` | `IsCraftedAbilitySkill` | scribing grimoire |
| `craftedAbilityId` | `integer?` | `GetCraftedAbilitySkillCraftedAbilityId` | when `isCrafted` |
| `upgradeLevel` | `integer?` | `GetSkillAbilityUpgradeInfo` (1st) | passives only |
| `maxUpgradeLevel` | `integer?` | `GetSkillAbilityUpgradeInfo` (2nd) | passives only |
