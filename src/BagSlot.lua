-- LibApiCompose — BagSlot.Compose + bag walkers (styles D, A, G)

local LAC = LibApiCompose
LAC.BagSlot = LAC.BagSlot or {}
local BagSlot = LAC.BagSlot
local SafeCall = LAC.SafeCall
local isGearType = LAC._internal.isGearType
local isGlyphType = LAC._internal.isGlyphType
local setCollectionFacts = LAC._internal.setCollectionFacts

local function isCompanionItem(bagId, slotIndex)
    if not GAMEPLAY_ACTOR_CATEGORY_COMPANION then
        return false
    end
    return SafeCall(GetItemActorCategory, bagId, slotIndex) == GAMEPLAY_ACTOR_CATEGORY_COMPANION
end

-- Bag groups for BagSlot.ForBags. Built from whichever constants exist on this client.
local function bagList(...)
    local list = {}
    for i = 1, select("#", ...) do
        local bagId = select(i, ...)
        if bagId ~= nil then
            list[#list + 1] = bagId
        end
    end
    return list
end

LAC.BAGS = {
    -- Personal bank: both halves share one UI but are separate bags.
    BANK = bagList(BAG_BANK, BAG_SUBSCRIBER_BANK),
    HOUSE_BANKS = bagList(
        BAG_HOUSE_BANK_ONE,
        BAG_HOUSE_BANK_TWO,
        BAG_HOUSE_BANK_THREE,
        BAG_HOUSE_BANK_FOUR,
        BAG_HOUSE_BANK_FIVE,
        BAG_HOUSE_BANK_SIX,
        BAG_HOUSE_BANK_SEVEN,
        BAG_HOUSE_BANK_EIGHT,
        BAG_HOUSE_BANK_NINE,
        BAG_HOUSE_BANK_TEN
    ),
}

--- Compose bag/slot → fresh snapshot record, or nil if empty.
--- Identity: bagId, slotIndex, id, link, uniqueId, uniqueIdString
--- Fields: type, specializedType, functionalQuality, displayQuality, stack, maxStack, icon,
---         sellValue, equipType, itemStyleId, meetsUsageRequirement, requiredLevel, requiredCP,
---         bindType, condition, isCompanion, isGear, isGlyph, isPlayerLocked, isSlotLocked,
---         isLocked, isJunk, isBound, isStolen, isUnique, isInArmory, isUsable,
---         isSetCollectionPiece, isSetCollectionUnlocked, name?, creatorName?
--- isLocked is true when the player locked the item OR the slot is transiently locked
--- (pending trade/mail/use) — check it before any destructive action.
--- opts.includeName — also fetch the formatted item name.
--- opts.includeCreator — also fetch the crafter's name.
function BagSlot.Compose(bagId, slotIndex, opts)
    opts = opts or {}
    if bagId == nil or slotIndex == nil then
        return nil
    end

    local itemId = SafeCall(GetItemId, bagId, slotIndex)
    if not itemId or itemId <= 0 then
        return nil
    end

    local link = SafeCall(GetItemLink, bagId, slotIndex, LINK_STYLE_DEFAULT or 0) or ""
    if link == "" then
        return nil
    end

    local typeOk, itemType, specializedType = LAC.SafeCallMulti(GetItemType, bagId, slotIndex)
    if not typeOk then
        itemType, specializedType = nil, nil
    end
    local stackOk, stack, maxStack = LAC.SafeCallMulti(GetSlotStackSize, bagId, slotIndex)
    if not stackOk then
        stack, maxStack = nil, nil
    end
    -- GetItemInfo -> icon, stack, sellPrice, meetsUsageRequirement, locked, equipType,
    --                itemStyleId, functionalQuality, displayQuality
    -- `locked` is the transient slot lock, NOT the player's lock toggle (IsItemPlayerLocked).
    local infoOk, icon, _, sellPrice, meetsUsage, slotLocked, equipType, itemStyleId, functionalQuality, displayQuality =
        LAC.SafeCallMulti(GetItemInfo, bagId, slotIndex)
    if not infoOk then
        icon, sellPrice, meetsUsage, slotLocked, equipType, itemStyleId, functionalQuality, displayQuality =
            nil, nil, nil, nil, nil, nil, nil, nil
    end
    if functionalQuality == nil then
        functionalQuality = SafeCall(GetItemFunctionalQuality, bagId, slotIndex)
    end
    if displayQuality == nil then
        displayQuality = SafeCall(GetItemDisplayQuality, bagId, slotIndex)
    end

    local uniqueId = SafeCall(GetItemUniqueId, bagId, slotIndex)
    local uniqueIdString = nil
    if uniqueId ~= nil then
        uniqueIdString = SafeCall(Id64ToString, uniqueId)
    end

    local name = nil
    if opts.includeName then
        name = LAC.NonEmpty(LAC.FormatName(SafeCall(GetItemName, bagId, slotIndex)))
    end
    local creatorName = nil
    if opts.includeCreator then
        creatorName = LAC.NonEmpty(SafeCall(GetItemCreatorName, bagId, slotIndex))
    end

    local isGear = isGearType(itemType)
    local isPlayerLocked = SafeCall(IsItemPlayerLocked, bagId, slotIndex) == true
    local isSlotLocked = slotLocked == true
    local isPiece, isPieceUnlocked = setCollectionFacts(link, itemId)

    return {
        bagId = bagId,
        slotIndex = slotIndex,
        id = itemId,
        link = link,
        uniqueId = uniqueId,
        uniqueIdString = uniqueIdString,
        name = name,
        creatorName = creatorName,
        type = itemType,
        specializedType = specializedType,
        functionalQuality = functionalQuality,
        displayQuality = displayQuality,
        stack = stack or 1,
        maxStack = maxStack,
        icon = LAC.NonEmpty(icon),
        sellValue = sellPrice,
        equipType = equipType,
        itemStyleId = itemStyleId,
        meetsUsageRequirement = meetsUsage,
        requiredLevel = SafeCall(GetItemRequiredLevel, bagId, slotIndex),
        requiredCP = SafeCall(GetItemRequiredChampionPoints, bagId, slotIndex),
        bindType = SafeCall(GetItemBindType, bagId, slotIndex),
        condition = isGear and SafeCall(GetItemCondition, bagId, slotIndex) or nil,
        isCompanion = isCompanionItem(bagId, slotIndex),
        isGear = isGear,
        isGlyph = isGlyphType(itemType),
        isPlayerLocked = isPlayerLocked,
        isSlotLocked = isSlotLocked,
        isLocked = isPlayerLocked or isSlotLocked,
        isJunk = SafeCall(IsItemJunk, bagId, slotIndex) == true,
        isBound = SafeCall(IsItemBound, bagId, slotIndex) == true,
        isStolen = SafeCall(IsItemStolen, bagId, slotIndex) == true,
        isUnique = SafeCall(IsItemLinkUnique, link) == true,
        isInArmory = SafeCall(IsItemInArmory, bagId, slotIndex) == true,
        isUsable = SafeCall(IsItemUsable, bagId, slotIndex) == true,
        isSetCollectionPiece = isPiece,
        isSetCollectionUnlocked = isPieceUnlocked,
    }
end

--- Convenience: bagId, slotIndex from a compose record.
function BagSlot.Args(rec)
    if not rec then
        return nil, nil
    end
    return rec.bagId, rec.slotIndex
end

------------------------------------------------------------
-- Bag walkers
------------------------------------------------------------

-- Bags walked by a "next slot id" API instead of 0 .. GetBagSize - 1. Slot ids end with nil.
local function linkedWalker(bagId)
    if BAG_VIRTUAL ~= nil and bagId == BAG_VIRTUAL then
        return GetNextVirtualBagSlotId
    end
    if BAG_GUILDBANK ~= nil and bagId == BAG_GUILDBANK then
        return GetNextGuildBankSlotId
    end
    return nil
end

-- Returns visited, stopped.
local function walkBag(bagId, fn, opts)
    local visited = 0
    local filter = opts and opts.filter

    local function visit(slotIndex)
        if filter then
            local itemType = SafeCall(GetItemType, bagId, slotIndex)
            if not filter(bagId, slotIndex, itemType) then
                return false
            end
        end
        local rec = BagSlot.Compose(bagId, slotIndex, opts)
        if rec then
            visited = visited + 1
            return fn(rec) == true
        end
        return false
    end

    local getNext = linkedWalker(bagId)
    if getNext then
        local guard = 0
        local slotId = SafeCall(getNext, nil)
        while slotId ~= nil and guard < LAC.Iterate.MAX_LINKED_STEPS do
            guard = guard + 1
            if visit(slotId) then
                return visited, true
            end
            local nextId = SafeCall(getNext, slotId)
            if nextId == slotId then
                break
            end
            slotId = nextId
        end
        return visited, false
    end

    local size = SafeCall(GetBagSize, bagId) or 0
    for slotIndex = 0, size - 1 do
        if visit(slotIndex) then
            return visited, true
        end
    end
    return visited, false
end

--- Walk every occupied slot of a bag: fn(rec) with a fresh Compose record.
--- Return true from fn to stop early. Returns the number of records visited.
--- Bag slot indices are 0-based; BAG_VIRTUAL (craft bag) and BAG_GUILDBANK are walked via their
--- "next slot id" APIs (the guild bank must be open and loaded).
--- opts.filter(bagId, slotIndex, itemType) — return false to skip a slot before it is composed.
--- Other opts are passed to Compose.
function BagSlot.ForBag(bagId, fn, opts)
    if bagId == nil or not fn then
        return 0
    end
    return (walkBag(bagId, fn, opts))
end

--- Walk several bags in order (e.g. LAC.BAGS.BANK). Same fn / opts contract as ForBag.
--- Returns the total number of records visited.
function BagSlot.ForBags(bagIds, fn, opts)
    if type(bagIds) ~= "table" or not fn then
        return 0
    end
    local total = 0
    for i = 1, #bagIds do
        local visited, stopped = walkBag(bagIds[i], fn, opts)
        total = total + visited
        if stopped then
            break
        end
    end
    return total
end

--- Collect mapFn(rec) (non-nil) for every occupied slot; records themselves when mapFn is nil.
--- bagId may be a single bag or a list of bags.
function BagSlot.MapBag(bagId, mapFn, opts)
    local list = {}
    local function collect(rec)
        local out = rec
        if mapFn then
            out = mapFn(rec)
        end
        if out ~= nil then
            list[#list + 1] = out
        end
    end
    if type(bagId) == "table" then
        BagSlot.ForBags(bagId, collect, opts)
    else
        BagSlot.ForBag(bagId, collect, opts)
    end
    return list
end

--- Worn equipment: list of Compose records with equipSlot (== slotIndex) and equipSlotName.
--- opts.companion — read the active companion's equipment (BAG_COMPANION_WORN) instead.
function BagSlot.ComposeWorn(opts)
    local bagId = BAG_WORN
    if opts and opts.companion then
        bagId = BAG_COMPANION_WORN
    end
    if bagId == nil then
        return {}
    end
    return BagSlot.MapBag(bagId, function(rec)
        rec.equipSlot = rec.slotIndex
        rec.equipSlotName = LAC.NonEmpty(SafeCall(GetString, "SI_EQUIPSLOT", rec.slotIndex))
        return rec
    end, opts)
end

LAC._internal.isCompanionItem = isCompanionItem
