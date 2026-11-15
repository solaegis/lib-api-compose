# Recipes

Complete, copyable patterns. Each one composes, decides, and leaves acting to you.

## Junk candidates

```lua
local LAC = LibApiCompose

--- Backpack items the player could mark as junk: trash or cheap stolen goods, never locked.
local function junkCandidates(maxValue)
    return LAC.BagSlot.MapBag(BAG_BACKPACK, function(slot)
        if slot.isLocked or slot.isJunk or slot.isCompanion then
            return nil
        end
        local isTrash = slot.type == ITEMTYPE_TRASH
        local isCheapStolen = slot.isStolen and (slot.sellValue or 0) <= maxValue
        if isTrash or isCheapStolen then
            return slot
        end
        return nil
    end)
end

for _, slot in ipairs(junkCandidates(5)) do
    SetItemIsJunk(slot.bagId, slot.slotIndex, true)
end
```

## Research candidates

```lua
local LAC = LibApiCompose

--- Researchable, unlocked, non-set gear in the backpack, grouped by trait name.
local function researchCandidates()
    local byTrait = {}
    LAC.BagSlot.ForBag(BAG_BACKPACK, function(slot)
        if not slot.isGear or slot.isLocked then
            return
        end
        local gear = LAC.Gear.ComposeFromSlot(slot.bagId, slot.slotIndex)
        if gear and gear.isResearchable and not gear.hasSet then
            local key = gear.trait.name or tostring(gear.traitType)
            byTrait[key] = byTrait[key] or {}
            table.insert(byTrait[key], gear)
        end
    end)
    return byTrait
end
```

## Worn set summary

```lua
local LAC = LibApiCompose

--- { [setId] = { name, count, max } } for equipped gear, using worn piece counts.
local function wornSets()
    local sets = {}
    for _, worn in ipairs(LAC.BagSlot.ComposeWorn()) do
        local gear = LAC.Gear.ComposeFromSlot(worn.bagId, worn.slotIndex, { equippedSetCounts = true })
        if gear and gear.hasSet and gear.set.id then
            sets[gear.set.id] = { name = gear.set.name, count = gear.set.count, max = gear.set.max }
        end
    end
    return sets
end

for _, set in pairs(wornSets()) do
    d(string.format("%s %d/%d", set.name or "?", set.count or 0, set.max or 0))
end
```

## Quickslot wheel display

```lua
local LAC = LibApiCompose

local function describeWheel()
    local wheel = LAC.Quickslot.ComposeWheel()
    for _, slot in ipairs(wheel.list) do
        if slot.isEmpty then
            d(string.format("%d: (empty)", slot.slotIndex))
        else
            d(string.format("%d: %s x%s %s", slot.slotIndex, slot.name or "?", tostring(slot.count or ""),
                slot.usable and "" or "(unusable)"))
        end
    end
end

describeWheel()
```

Selecting or re-binding a slot is your addon's job, for example
`SelectSlotSimpleAction(rec.actionType, rec.actionId, rec.slotIndex)`.

## Active companion status

```lua
local LAC = LibApiCompose

local function companionLine()
    local companion = LAC.Companion.ComposeActive()
    if not companion then
        return "No companion summoned"
    end
    return string.format("%s (collectible %d)", companion.name or "?", companion.collectibleId or 0)
end

d(companionLine())
```

## Mount lookup by name (user input)

```lua
local LAC = LibApiCompose

--- Resolve a typed mount name to an owned collectible record.
local function findOwnedMount(typed)
    local id = LAC.Collectible.FindByName(COLLECTIBLE_CATEGORY_TYPE_MOUNT, typed)
    if not id then
        return nil, "no mount called " .. typed
    end
    local rec = LAC.Collectible.Compose(id)
    if not rec.unlocked then
        return nil, tostring(rec.name) .. " is not unlocked"
    end
    return rec
end

local mount, err = findOwnedMount("Bay Dun Horse")
if mount then
    UseCollectible(mount.id)
else
    d(err)
end
```

## Potion cooldown preview

```lua
local LAC = LibApiCompose

local function onUseSummary(link)
    local onUse = LAC.ItemLink.ComposeOnUse(link)
    if not onUse or not onUse.hasAbility then
        return nil
    end
    return string.format("%s — %s (cooldown %ds)", onUse.header or "", onUse.description or "",
        math.floor((onUse.cooldown or 0) / 1000))
end

local slot = LAC.BagSlot.Compose(BAG_BACKPACK, 0)
if slot then
    d(onUseSummary(slot.link))
end
```

## Craft bag totals by item type

```lua
local LAC = LibApiCompose

local function craftBagTotals()
    local totals = {}
    LAC.BagSlot.ForBag(BAG_VIRTUAL, function(slot)
        totals[slot.type] = (totals[slot.type] or 0) + (slot.stack or 0)
    end)
    return totals
end
```

## Item tracking across sessions

```lua
local LAC = LibApiCompose

MyAddon = MyAddon or {}

--- Remember notes per item, surviving bag moves and relogs.
local function noteFor(sv, slot)
    return slot.uniqueIdString and sv.notes[slot.uniqueIdString] or nil
end

local function setNote(sv, slot, text)
    if slot.uniqueIdString then
        sv.notes[slot.uniqueIdString] = text
    end
end

MyAddon.noteFor = noteFor
MyAddon.setNote = setNote
```
