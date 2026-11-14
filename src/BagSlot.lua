-- LibApiCompose — BagSlot.Compose (style D)

local LAC = LibApiCompose
LAC.BagSlot = LAC.BagSlot or {}
local BagSlot = LAC.BagSlot

local function getItemFunctionalQuality(bagId, slotIndex)
    if GetItemFunctionalQuality then
        return LAC.SafeCall(GetItemFunctionalQuality, bagId, slotIndex)
    end
    if GetItemQuality then
        return LAC.SafeCall(GetItemQuality, bagId, slotIndex)
    end
    return nil
end

local function isCompanionItem(bagId, slotIndex)
    if GetItemActorCategory and GAMEPLAY_ACTOR_CATEGORY_COMPANION then
        return LAC.SafeCall(GetItemActorCategory, bagId, slotIndex) == GAMEPLAY_ACTOR_CATEGORY_COMPANION
    end
    return false
end

local function isWeaponArmorOrJewelry(bagId, slotIndex)
    local itemType = LAC.SafeCall(GetItemType, bagId, slotIndex)
    return itemType == ITEMTYPE_WEAPON or itemType == ITEMTYPE_ARMOR
end

local function isGlyph(bagId, slotIndex)
    local itemType = LAC.SafeCall(GetItemType, bagId, slotIndex)
    return itemType == ITEMTYPE_GLYPH_ARMOR
        or itemType == ITEMTYPE_GLYPH_JEWELRY
        or itemType == ITEMTYPE_GLYPH_WEAPON
end

--- Compose bag/slot → snapshot record, or nil if empty.
--- Identity: bagId, slotIndex, id, link
--- Fields: type, functionalQuality, stack, isCompanion, isGear, isGlyph, name?
--- opts: reserved for additive minors (e.g. includeName)
function BagSlot.Compose(bagId, slotIndex, opts)
    opts = opts or {}
    if bagId == nil or slotIndex == nil then
        return nil
    end

    local itemId = LAC.SafeCall(GetItemId, bagId, slotIndex)
    if not itemId or itemId <= 0 then
        return nil
    end

    local linkStyle = LINK_STYLE_DEFAULT or 0
    local link = LAC.SafeCall(GetItemLink, bagId, slotIndex, linkStyle) or ""
    if link == "" then
        return nil
    end

    local itemType = LAC.SafeCall(GetItemType, bagId, slotIndex)
    local stack = LAC.SafeCall(GetSlotStackSize, bagId, slotIndex) or 1
    local name = nil
    if opts.includeName and GetItemName then
        name = LAC.SafeCall(GetItemName, bagId, slotIndex)
    end

    return {
        bagId = bagId,
        slotIndex = slotIndex,
        id = itemId,
        link = link,
        name = name,
        type = itemType,
        functionalQuality = getItemFunctionalQuality(bagId, slotIndex),
        stack = stack,
        isCompanion = isCompanionItem(bagId, slotIndex),
        isGear = isWeaponArmorOrJewelry(bagId, slotIndex),
        isGlyph = isGlyph(bagId, slotIndex),
    }
end

--- Convenience: bagId, slotIndex from a compose record.
function BagSlot.Args(rec)
    if not rec then
        return nil, nil
    end
    return rec.bagId, rec.slotIndex
end

-- Internal helpers shared with Gear (not public contract beyond module)
BagSlot._getItemFunctionalQuality = getItemFunctionalQuality
BagSlot._isCompanionItem = isCompanionItem
BagSlot._isWeaponArmorOrJewelry = isWeaponArmorOrJewelry
BagSlot._isGlyph = isGlyph
