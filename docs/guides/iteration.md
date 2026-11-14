# Iteration

ZOS exposes collections in a few recurring shapes. LAC has one walker per shape. Every count and lookup goes
through `SafeCall`, so a failing API gives you an empty walk instead of an error. Your callback is **not**
wrapped — errors in your own code still surface.

| Shape | ZOS pattern | LAC |
|---|---|---|
| Flat list | `GetNumX()` + `GetX(i)` | `ForIndex`, `MapIndex` |
| Nested lists | `GetNumA()`, `GetNumB(a)`, `GetC(a, b)` | `NestedFor`, `NestedMap` |
| Linked ids | `GetNextX(lastId)` | `ForLinked` |
| Bag slots | `GetBagSize(bag)`, slots `0..size-1`; craft bag by id | `BagSlot.ForBag`, `BagSlot.MapBag` |

The `Iterate` functions are also exposed directly on `LAC` (`LAC.ForIndex` is `LAC.Iterate.ForIndex`).

## Flat lists

```lua
local LAC = LibApiCompose

-- fn(i, value) for i = 1..GetNumBuffs("player")
LAC.ForIndex(function()
    return GetNumBuffs("player")
end, nil, function(i)
    local ok, buffName = LAC.SafeCallMulti(GetUnitBuffInfo, "player", i)
    if ok then
        d(i, buffName)
    end
end)
```

`getNum` is called with no arguments, so wrap APIs that need arguments in a closure.

When `getAt` returns several values, pass `needMulti = true` and receive up to eight of them:

```lua
local LAC = LibApiCompose

local buffs = LAC.MapIndex(function()
    return GetNumBuffs("player")
end, function(i)
    return GetUnitBuffInfo("player", i)
end, function(i, buffName, timeStarted, timeEnding)
    return { index = i, name = buffName, ends = timeEnding }
end, true)
```

With `needMulti`, an index whose `getAt` errors is skipped. Without it, `fn` is called with `nil`.
`MapIndex` drops `nil` results, so returning `nil` filters.

## Nested lists

Each level's `getNum` receives the indices of the levels above it. Your leaf callback receives all indices.

```lua
local LAC = LibApiCompose

local lines = LAC.NestedMap({
    { getNum = GetNumSkillTypes },
    { getNum = GetNumSkillLines },
}, function(skillType, skillLineIndex)
    local name = LAC.SafeCall(GetSkillLineName, skillType, skillLineIndex)
    return { skillType = skillType, skillLineIndex = skillLineIndex, name = name }
end)
```

## Linked ids

`getNext(nil)` must return the first id and `getNext(id)` the next; `nil` ends the walk.

```lua
local LAC = LibApiCompose

local craftBagIds = LAC.ForLinked(GetNextVirtualBagSlotId)
```

A walk stops after `maxSteps` (default `LAC.Iterate.MAX_LINKED_STEPS`, 100000) so a buggy or cyclic `getNext`
can't freeze the client. Hitting the limit is logged to LibDebugLogger.

## Bags

`BagSlot.ForBag` composes every occupied slot and hands you the record. It knows two things that are easy to
get wrong by hand:

- bag slot indices are **0-based** (`0 .. GetBagSize(bag) - 1`);
- the craft bag (`BAG_VIRTUAL`) has no size — its slot index is the item id, walked with
  `GetNextVirtualBagSlotId`.

```lua
local LAC = LibApiCompose

-- Count and stop early: return true from the callback to stop.
local firstPotion
LAC.BagSlot.ForBag(BAG_BACKPACK, function(slot)
    if slot.type == ITEMTYPE_POTION then
        firstPotion = slot
        return true
    end
end)

-- Collect: return nil to skip.
local stolen = LAC.BagSlot.MapBag(BAG_BACKPACK, function(slot)
    return slot.isStolen and slot or nil
end)

-- Craft bag works the same way.
local materials = LAC.BagSlot.MapBag(BAG_VIRTUAL)
```

`ForBag` returns how many records it visited. Each record costs roughly 15 ZOS calls, so walking a full bank is
a few thousand calls — fine on an event, not every frame. See [Best practices](best-practices.md#performance).
