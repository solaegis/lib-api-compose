# Record schemas

Every record shape at a glance. Types, sources and notes are on each module page (linked). `?` marks a field
that can be `nil`. String fields are `nil`, never `""`, when the game has no value.

## Item link record

From [`ItemLink.Compose`](itemlink.md#record).

```text
{
  link, id,                                   -- identity
  name?,                                      -- opts.includeName
  type?, specializedType?, functionalQuality?, displayQuality?,
  icon?, sellValue?, equipType?, itemStyleId?,
  meetsUsageRequirement?, requiredLevel?, requiredCP?, bindType?,
  isBound, isStolen, isCrafted, isUnique, isCompanion, isGear, isGlyph,
  isSetCollectionPiece, isSetCollectionUnlocked,
}
```

## BagSlot record

From [`BagSlot.Compose`](bagslot.md#record), `ForBag`, `ForBags`, `MapBag`, `ComposeWorn`.

```text
{
  bagId, slotIndex, id, link,                 -- identity
  uniqueId?, uniqueIdString?,                 -- identity across moves
  name?, creatorName?,                        -- opts.includeName / opts.includeCreator
  type?, specializedType?, functionalQuality?, displayQuality?,
  stack, maxStack?, icon?, sellValue?, equipType?, itemStyleId?,
  meetsUsageRequirement?, requiredLevel?, requiredCP?, bindType?, condition?,
  isCompanion, isGear, isGlyph,
  isPlayerLocked, isSlotLocked, isLocked,     -- isLocked = either
  isJunk, isBound, isStolen, isUnique, isInArmory, isUsable,
  isSetCollectionPiece, isSetCollectionUnlocked,
  equipSlot?, equipSlotName?,                 -- ComposeWorn only
}
```

## Gear record

From [`Gear.ComposeFromSlot`](gear.md#record) (a BagSlot record plus) and `Gear.ComposeFromLink` (an item link
record plus):

```text
{
  hasSet,
  set = { hasSet, id?, name?, count?, perfectedCount?, max? },
  traitType?,
  trait = { id?, name? },
  isIntricate, isOrnate, isResearchable, armorType?, weaponType?,
  canMarkJunk?,                               -- ComposeFromSlot only
  enchant = { hasEnchant, hasCharges, name?, description?,
              charges?, maxCharges? },        -- charges: ComposeFromSlot only
}
```

## Collectible record

From [`Collectible.Compose`](collectible.md#record), `ComposeUnlockedByCategory`, `Companion.ComposeRoster`.

```text
{
  id, name?, nickname?, icon?, category?,
  unlocked, unlockState?, active, isBlocked,
  cooldownRemaining?, cooldownDuration?,
  description?, link?,                        -- opts.includeDescription / opts.includeLink
}
```

## Quickslot record

From [`Quickslot.Compose`](quickslot.md#record), `ComposeWheel`.

```text
{
  hotbarCategory, slotIndex, actionType?, actionId?,   -- identity
  isEmpty, isCurrent, name?, texture?, icon?, count?, usable, itemLink?,
  cooldownRemaining?, cooldownDuration?, collectibleCategory?,
}
```

## Hotbar record

From [`Hotbar.ComposeSlot`](hotbar.md#record), `ComposeBar`.

```text
{
  hotbarCategory, slotIndex, actionType?, actionId?,   -- identity
  isEmpty, isUltimate, abilityId?, craftedAbilityId?, name?, icon?, usable,
  cooldownRemaining?, cooldownDuration?,
}
```

## ItemLink on-use record

From [`ItemLink.ComposeOnUse`](itemlink.md#on-use-record).

```text
{
  link, icon?, hasAbility, header?, description?, cooldown?, remainingCooldown?,
  hasScaling, minLevel?, maxLevel?, isChampionPoints,
}
```

## Companion record

From [`Companion.ComposeActive`](companion.md#record).

```text
{
  defId?, collectibleId?, id?, name?, icon?, isActive, isPending,
  level?, xp?, rapport?, rapportLevel?,       -- active companion only
}
```

## Unit record

From [`Unit.Compose`](unit.md#record).

```text
{
  unitTag,                                    -- identity
  name?, displayName?, level?, championPoints?, effectiveChampionPoints?,
  classId?, className?, raceId?, raceName?, alliance?, allianceName?, gender?, zoneName?,
  isPlayer, isDead, isInCombat, isOnline,
  health?, magicka?, stamina?,                -- { current, max, effectiveMax }; absent with opts.skipPower
}
```

## Currency record

From [`Currency.Compose`](currency.md#record), `ComposeAll`.

```text
{ type, location, amount, max?, name?, icon?, canBeStored }
```

## Skill line record

From [`Skill.ComposeLine`](skill.md#line-record), `ComposeLines`.

```text
{
  skillType, lineIndex, id,                   -- identity
  name?, rank?, isActive, isDiscovered, isAdvised,
  xp? = { last, next, current },
}
```

## Skill ability record

From [`Skill.ComposeAbility`](skill.md#ability-record), `ComposeAbilities`, `ForEachAbility`.

```text
{
  skillType, lineIndex, abilityIndex, abilityId?,      -- identity
  name, icon?, earnedRank?, rank?, isPassive, isUltimate, isPurchased, progressionIndex?,
  isCrafted, craftedAbilityId?, upgradeLevel?, maxUpgradeLevel?,
}
```

## Buff record

From [`Buff.ComposeAll`](buff.md#record), `Find`.

```text
{
  unitTag, index, abilityId?,                 -- identity (index is short-lived)
  name?, icon?, startTime?, endTime?, isPermanent, buffSlot?, stacks?,
  effectType?, abilityType?, statusEffectType?, isDebuff, canClickOff, castByPlayer,
}
```

## Aggregate result

From `Collectible.ComposeUnlockedByCategory`, `Companion.ComposeRoster`, `Quickslot.ComposeWheel`,
`Hotbar.ComposeBar`, `Currency.ComposeAll`.

```text
{ list = { rec, ... }, count, total }
```
