-- LibApiCompose — BagSlot.Compose + bag walkers (styles D, A, G)

local LAC = LibApiCompose
LAC.BagSlot = LAC.BagSlot or {}
local BagSlot = LAC.BagSlot
local SafeCall = LAC.SafeCall

local function getFunctionalQuality(bagId, slotIndex)
    if GetItemFunctionalQuality then
        return SafeCall(GetItemFunctionalQuality, bagId, slotIndex)
    end
    return SafeCall(GetItemQuality, bagId, slotIndex)
end

local function isCompanionItem(bagId, slotIndex)
    if not GAMEPLAY_ACTOR_CATEGORY_COMPANION then
        return false
    end
    return SafeCall(GetItemActorCategory, bagId, slotIndex) == GAMEPLAY_ACTOR_CATEGORY_COMPANION
end

local function isGearType(itemType)
    -- Jewelry is ITEMTYPE_ARMOR in ESO.
    return itemType ~= nil and (itemType == ITEMTYPE_WEAPON or itemType == ITEMTYPE_ARMOR)
end

local function isGlyphType(itemType)
    return itemType ~= nil
        and (
            itemType == ITEMTYPE_GLYPH_ARMOR
            or itemType == ITEMTYPE_GLYPH_JEWELRY
            or itemType == ITEMTYPE_GLYPH_WEAPON
        )
end

--- Compose bag/slot → fresh snapshot record, or nil if empty.
--- Identity: bagId, slotIndex, id, link, uniqueId, uniqueIdString
--- Fields: type, functionalQuality, displayQuality, stack, maxStack, icon, sellValue,
---         equipType, meetsUsageRequirement, requiredLevel, requiredCP,
---         isCompanion, isGear, isGlyph, isLocked, isJunk, isBound, isStolen, name?
--- opts.includeName — also fetch the formatted item name.
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

    local itemType = SafeCall(GetItemType, bagId, slotIndex)
    local stackOk, stack, maxStack = LAC.SafeCallMulti(GetSlotStackSize, bagId, slotIndex)
    if not stackOk then
        stack, maxStack = nil, nil
    end
    local infoOk, icon, _, sellPrice, meetsUsage, locked, equipType, _, displayQuality =
        LAC.SafeCallMulti(GetItemInfo, bagId, slotIndex)
    if not infoOk then
        icon, sellPrice, meetsUsage, locked, equipType, displayQuality = nil, nil, nil, nil, nil, nil
    end
    if locked == nil then
        locked = SafeCall(IsItemPlayerLocked, bagId, slotIndex)
    end

    local uniqueId = SafeCall(GetItemUniqueId, bagId, slotIndex)
    local uniqueIdString = nil
    if uniqueId ~= nil then
        uniqueIdString = SafeCall(Id64ToString, uniqueId)
    end

    local name = nil
    if opts.includeName then
        name = LAC.FormatName(SafeCall(GetItemName, bagId, slotIndex))
    end

    return {
        bagId = bagId,
        slotIndex = slotIndex,
        id = itemId,
        link = link,
        uniqueId = uniqueId,
        uniqueIdString = uniqueIdString,
        name = name,
        type = itemType,
        functionalQuality = getFunctionalQuality(bagId, slotIndex),
        displayQuality = displayQuality or SafeCall(GetItemDisplayQuality, bagId, slotIndex),
        stack = stack or 1,
        maxStack = maxStack,
        icon = icon,
        sellValue = sellPrice,
        equipType = equipType,
        meetsUsageRequirement = meetsUsage,
        requiredLevel = SafeCall(GetItemRequiredLevel, bagId, slotIndex),
        requiredCP = SafeCall(GetItemRequiredChampionPoints, bagId, slotIndex),
        isCompanion = isCompanionItem(bagId, slotIndex),
        isGear = isGearType(itemType),
        isGlyph = isGlyphType(itemType),
        isLocked = locked == true,
        isJunk = SafeCall(IsItemJunk, bagId, slotIndex) == true,
        isBound = SafeCall(IsItemBound, bagId, slotIndex) == true,
        isStolen = SafeCall(IsItemStolen, bagId, slotIndex) == true,
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

--- Walk every occupied slot of a bag: fn(rec) with a fresh Compose record.
--- Return true from fn to stop early. Returns the number of records visited.
--- Bag slot indices are 0-based; BAG_VIRTUAL (craft bag) is walked via GetNextVirtualBagSlotId.
function BagSlot.ForBag(bagId, fn, opts)
    if bagId == nil or not fn then
        return 0
    end
    local visited = 0

    local function visit(slotIndex)
        local rec = BagSlot.Compose(bagId, slotIndex, opts)
        if rec then
            visited = visited + 1
            return fn(rec) == true
        end
        return false
    end

    if BAG_VIRTUAL ~= nil and bagId == BAG_VIRTUAL then
        local guard = 0
        local slotId = SafeCall(GetNextVirtualBagSlotId, nil)
        while slotId and guard < LAC.Iterate.MAX_LINKED_STEPS do
            guard = guard + 1
            if visit(slotId) then
                break
            end
            slotId = SafeCall(GetNextVirtualBagSlotId, slotId)
        end
        return visited
    end

    local size = SafeCall(GetBagSize, bagId) or 0
    for slotIndex = 0, size - 1 do
        if visit(slotIndex) then
            break
        end
    end
    return visited
end

--- Collect mapFn(rec) (non-nil) for every occupied slot; records themselves when mapFn is nil.
function BagSlot.MapBag(bagId, mapFn, opts)
    local list = {}
    BagSlot.ForBag(bagId, function(rec)
        local out = rec
        if mapFn then
            out = mapFn(rec)
        end
        if out ~= nil then
            list[#list + 1] = out
        end
    end, opts)
    return list
end

--- Worn equipment: list of Compose records with equipSlot (== slotIndex) and equipSlotName.
function BagSlot.ComposeWorn(opts)
    if BAG_WORN == nil then
        return {}
    end
    return BagSlot.MapBag(BAG_WORN, function(rec)
        rec.equipSlot = rec.slotIndex
        rec.equipSlotName = SafeCall(GetString, "SI_EQUIPSLOT", rec.slotIndex)
        return rec
    end, opts)
end

LAC._internal.isCompanionItem = isCompanionItem
LAC._internal.isGearType = isGearType
LAC._internal.isGlyphType = isGlyphType
