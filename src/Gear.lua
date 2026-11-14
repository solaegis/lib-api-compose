-- LibApiCompose — Gear.ComposeFromSlot (style D, extends BagSlot)

local LAC = LibApiCompose
LAC.Gear = LAC.Gear or {}
local Gear = LAC.Gear

local function isIntricateTrait(traitType)
    if not traitType then
        return false
    end
    return traitType == ITEM_TRAIT_TYPE_WEAPON_INTRICATE
        or traitType == ITEM_TRAIT_TYPE_ARMOR_INTRICATE
        or traitType == ITEM_TRAIT_TYPE_JEWELRY_INTRICATE
end

local function canMarkAsJunk(bagId, slotIndex)
    local BagSlot = LAC.BagSlot
    if BagSlot._isCompanionItem(bagId, slotIndex) then
        return false
    end
    if IsItemJunk and LAC.SafeCall(IsItemJunk, bagId, slotIndex) then
        return false
    end
    if IsItemPlayerLocked and LAC.SafeCall(IsItemPlayerLocked, bagId, slotIndex) then
        return false
    end
    if CanItemBeMarkedAsJunk then
        return LAC.SafeCall(CanItemBeMarkedAsJunk, bagId, slotIndex) == true
    end
    return true
end

--- Compose gear triage fields on top of BagSlot.
--- Returns nil if slot empty. Always includes BagSlot identity fields.
--- opts.equippedSetCounts — if true, GetItemLinkSetInfo(link, true) for worn counts
function Gear.ComposeFromSlot(bagId, slotIndex, opts)
    opts = opts or {}
    local base = LAC.BagSlot.Compose(bagId, slotIndex, opts)
    if not base then
        return nil
    end

    local link = base.link
    local equipped = opts.equippedSetCounts == true
    local ok, hasSet, setName, _, numEquipped, maxEquipped, setId =
        LAC.SafeCallMulti(GetItemLinkSetInfo, link, equipped)
    if not ok then
        hasSet = false
    end

    local traitType = nil
    if GetItemLinkTraitType then
        traitType = LAC.SafeCall(GetItemLinkTraitType, link)
    elseif GetItemTrait then
        traitType = LAC.SafeCall(GetItemTrait, bagId, slotIndex)
    end

    local traitName = nil
    if traitType and traitType > 0 and GetString then
        traitName = LAC.SafeCall(GetString, "SI_ITEMTRAITTYPE", traitType)
    end

    local isResearchable = false
    if CanItemLinkBeTraitResearched and traitType and traitType ~= ITEM_TRAIT_TYPE_NONE then
        isResearchable = LAC.SafeCall(CanItemLinkBeTraitResearched, link) == true
    end

    local _, hasCharges, enchantHeader, enchantDescription = LAC.SafeCallMulti(GetItemLinkEnchantInfo, link)

    base.hasSet = hasSet and true or false
    base.set = {
        hasSet = base.hasSet,
        id = setId,
        name = setName,
        count = numEquipped,
        max = maxEquipped,
    }
    base.traitType = traitType
    base.trait = {
        id = traitType,
        name = traitName,
    }
    base.isIntricate = isIntricateTrait(traitType)
    base.isResearchable = isResearchable
    base.canMarkJunk = canMarkAsJunk(bagId, slotIndex)
    base.enchant = {
        hasEnchant = hasCharges and true or false,
        name = enchantHeader or enchantDescription,
    }

    return base
end
