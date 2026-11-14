# Quick start

This page walks through the three things almost every consumer does: call an API safely, compose a record,
and act on it.

## 1. Call any ZOS API safely

```lua
local LAC = LibApiCompose

-- Single return value: SafeCall returns it, or nil if the call errored or the API doesn't exist.
local level = LAC.SafeCall(GetUnitLevel, "player") or 0

-- Several return values: SafeCallMulti returns ok first, then every value (nil holes preserved).
local ok, hasSet, setName = LAC.SafeCallMulti(GetItemLinkSetInfo, "|H0:item:123|h|h", false)
if ok and hasSet then
    d(setName)
end
```

You don't need any compose module to use these. See the [SafeCall guide](../guides/safecall.md).

## 2. Compose a record

```lua
local LAC = LibApiCompose

local slot = LAC.BagSlot.Compose(BAG_BACKPACK, 0)
if slot then
    d(slot.link, slot.stack, slot.isLocked)
end
```

`BagSlot.Compose` returns `nil` for an empty slot, otherwise a **fresh table** with identity fields (`bagId`,
`slotIndex`, `id`, `link`, `uniqueId`) and facts (`type`, quality, flags, value…). You own the table; changing
it affects nothing else. The full field list is in [BagSlot](../reference/bagslot.md#record).

## 3. Decide, then act with the identity fields

```lua
local LAC = LibApiCompose

local function junkCheapStolenItems()
    LAC.BagSlot.ForBag(BAG_BACKPACK, function(slot)
        if slot.isStolen and not slot.isLocked and not slot.isJunk and (slot.sellValue or 0) < 10 then
            -- Acting is your addon's job, with the raw handles from the record.
            SetItemIsJunk(slot.bagId, slot.slotIndex, true)
        end
    end)
end

junkCheapStolenItems()
```

LAC never writes to the game. That keeps it safe to call from anywhere and leaves protected-call and combat
rules to your addon.

## 4. Walk things

```lua
local LAC = LibApiCompose

-- Every occupied slot in a bag (0-based indices, craft bag supported). Return true to stop early.
local count = LAC.BagSlot.ForBag(BAG_BACKPACK, function(slot)
    return slot.id == 64710 -- stop at the first Crown Repair Kit
end)

-- Every slot on the quickslot wheel, empty ones included.
local wheel = LAC.Quickslot.ComposeWheel()
d(string.format("%d of %d quickslots used, visited %d bag slots", wheel.count, wheel.total, count))
```

## Next

- [Core concepts](../guides/concepts.md) — the mental model behind records.
- [Recipes](../guides/recipes.md) — complete, copyable patterns.
- [API reference](../reference/index.md) — every function and field.
