-- LibApiCompose — Gear.ComposeFromSlot (style D, extends BagSlot)

local LAC = LibApiCompose
LAC.Gear = LAC.Gear or {}
local Gear = LAC.Gear
local SafeCall = LAC.SafeCall

local function isIntricateTrait(traitType)
    if not traitType then
        return false
    end
    return traitType == ITEM_TRAIT_TYPE_WEAPON_INTRICATE
        or traitType == ITEM_TRAIT_TYPE_ARMOR_INTRICATE
        or traitType == ITEM_TRAIT_TYPE_JEWELRY_INTRICATE
end

local function canMarkAsJunk(base)
    if CanItemBeMarkedAsJunk then
        return SafeCall(CanItemBeMarkedAsJunk, base.bagId, base.slotIndex) == true
    end
    return not base.isCompanion and not base.isLocked
end

local function nonEmpty(s)
    return type(s) == "string" and s ~= ""
end

--- Compose gear triage fields on top of BagSlot.
--- Returns nil if slot empty. Always includes BagSlot identity + fields.
--- Non-gear items get the same shape with empty/false gear fields (no extra ZOS calls).
--- Fields: hasSet, set{hasSet,id,name,count,perfectedCount,max}, traitType, trait{id,name},
---         isIntricate, isResearchable, canMarkJunk, enchant{hasEnchant,hasCharges,name,description}
--- canMarkJunk mirrors CanItemBeMarkedAsJunk (true even if already junk; see isJunk).
--- opts.equippedSetCounts — if true, GetItemLinkSetInfo(link, true) for worn counts.
function Gear.ComposeFromSlot(bagId, slotIndex, opts)
    opts = opts or {}
    local base = LAC.BagSlot.Compose(bagId, slotIndex, opts)
    if not base then
        return nil
    end

    base.hasSet = false
    base.set = { hasSet = false }
    base.traitType = nil
    base.trait = {}
    base.isIntricate = false
    base.isResearchable = false
    base.canMarkJunk = canMarkAsJunk(base)
    base.enchant = { hasEnchant = false, hasCharges = false }

    if not base.isGear then
        return base
    end

    local link = base.link
    local ok, hasSet, setName, _, numEquipped, maxEquipped, setId, numPerfected =
        LAC.SafeCallMulti(GetItemLinkSetInfo, link, opts.equippedSetCounts == true)
    if ok and hasSet then
        base.hasSet = true
        base.set = {
            hasSet = true,
            id = setId,
            name = LAC.FormatName(setName),
            count = numEquipped,
            perfectedCount = numPerfected,
            max = maxEquipped,
        }
    end

    local traitType
    if GetItemLinkTraitType then
        traitType = SafeCall(GetItemLinkTraitType, link)
    else
        traitType = SafeCall(GetItemTrait, bagId, slotIndex)
    end
    local hasTrait = traitType ~= nil and traitType ~= (ITEM_TRAIT_TYPE_NONE or 0)
    base.traitType = traitType
    base.trait = {
        id = traitType,
        name = hasTrait and SafeCall(GetString, "SI_ITEMTRAITTYPE", traitType) or nil,
    }
    base.isIntricate = isIntricateTrait(traitType)
    base.isResearchable = hasTrait and SafeCall(CanItemLinkBeTraitResearched, link) == true

    local eOk, hasCharges, enchantHeader, enchantDescription = LAC.SafeCallMulti(GetItemLinkEnchantInfo, link)
    if eOk then
        base.enchant = {
            -- Jewelry enchants have no charges, so presence is judged by the header text.
            hasEnchant = nonEmpty(enchantHeader) or nonEmpty(enchantDescription),
            hasCharges = hasCharges == true,
            name = nonEmpty(enchantHeader) and enchantHeader or nil,
            description = nonEmpty(enchantDescription) and enchantDescription or nil,
        }
    end

    return base
end
