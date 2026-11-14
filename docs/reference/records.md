# Record schemas

Every record shape at a glance. Types, sources and notes are on each module page (linked). `?` marks a field
that can be `nil`.

## BagSlot record

From [`BagSlot.Compose`](bagslot.md#record), `ForBag`, `MapBag`, `ComposeWorn`.

```text
{
  bagId, slotIndex, id, link,                 -- identity
  uniqueId?, uniqueIdString?,                 -- identity across moves
  name?,                                      -- opts.includeName
  type?, functionalQuality?, displayQuality?,
  stack, maxStack?, icon?, sellValue?, equipType?,
  meetsUsageRequirement?, requiredLevel?, requiredCP?,
  isCompanion, isGear, isGlyph, isLocked, isJunk, isBound, isStolen,
  equipSlot?, equipSlotName?,                 -- ComposeWorn only
}
```

## Gear record

From [`Gear.ComposeFromSlot`](gear.md#record). A BagSlot record plus:

```text
{
  hasSet,
  set = { hasSet, id?, name?, count?, perfectedCount?, max? },
  traitType?,
  trait = { id?, name? },
  isIntricate, isResearchable, canMarkJunk,
  enchant = { hasEnchant, hasCharges, name?, description? },
}
```

## Collectible record

From [`Collectible.Compose`](collectible.md#record), `ComposeUnlockedByCategory`, `Companion.ComposeRoster`.

```text
{ id, name?, nickname?, icon?, category?, unlocked, active }
```

## Quickslot record

From [`Quickslot.Compose`](quickslot.md#record), `ComposeWheel`.

```text
{
  hotbarCategory, slotIndex, actionType?, actionId?,   -- identity
  isEmpty, name?, texture?, icon?, count?, usable, collectibleCategory?,
}
```

## ItemLink on-use record

From [`ItemLink.ComposeOnUse`](itemlink.md#record).

```text
{ link, icon?, hasAbility, header?, description?, cooldown?, remainingCooldown? }
```

## Companion record

From [`Companion.ComposeActive`](companion.md#record).

```text
{ defId?, collectibleId?, id?, name?, icon?, isActive }
```

## Aggregate result

From `Collectible.ComposeUnlockedByCategory`, `Companion.ComposeRoster`, `Quickslot.ComposeWheel`.

```text
{ list = { rec, ... }, count, total }
```
