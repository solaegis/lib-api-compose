-- LibApiCompose — Gear.ComposeFromSlot / ComposeFromLink (style D, extends BagSlot / ItemLink)

local LAC = LibApiCompose
LAC.Gear = LAC.Gear or {}
local Gear = LAC.Gear
local SafeCall = LAC.SafeCall
local NonEmpty = LAC.NonEmpty

local function isIntricateTrait(traitType)
    if not traitType then
        return false
    end
    return traitType == ITEM_TRAIT_TYPE_WEAPON_INTRICATE
        or traitType == ITEM_TRAIT_TYPE_ARMOR_INTRICATE
        or traitType == ITEM_TRAIT_TYPE_JEWELRY_INTRICATE
end

local function isOrnateTrait(traitType)
    if not traitType then
        return false
    end
    return traitType == ITEM_TRAIT_TYPE_WEAPON_ORNATE
        or traitType == ITEM_TRAIT_TYPE_ARMOR_ORNATE
        or traitType == ITEM_TRAIT_TYPE_JEWELRY_ORNATE
end

local function canMarkAsJunk(base)
    if CanItemBeMarkedAsJunk then
        return SafeCall(CanItemBeMarkedAsJunk, base.bagId, base.slotIndex) == true
    end
    return not base.isCompanion and not base.isLocked
end

-- Adds the gear fields to a BagSlot or ItemLink record (single implementation for both).
local function enrich(base, opts)
    base.hasSet = false
    base.set = { hasSet = false }
    base.traitType = nil
    base.trait = {}
    base.isIntricate = false
    base.isOrnate = false
    base.isResearchable = false
    base.armorType = nil
    base.weaponType = nil
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
            name = NonEmpty(LAC.FormatName(setName)),
            count = numEquipped,
            perfectedCount = numPerfected,
            max = maxEquipped,
        }
    end

    local traitType = SafeCall(GetItemLinkTraitType, link)
    local hasTrait = traitType ~= nil and traitType ~= (ITEM_TRAIT_TYPE_NONE or 0)
    base.traitType = traitType
    base.trait = {
        id = traitType,
        name = hasTrait and NonEmpty(SafeCall(GetString, "SI_ITEMTRAITTYPE", traitType)) or nil,
    }
    base.isIntricate = isIntricateTrait(traitType)
    base.isOrnate = isOrnateTrait(traitType)
    base.isResearchable = hasTrait and SafeCall(CanItemLinkBeTraitResearched, link) == true
    base.armorType = SafeCall(GetItemLinkArmorType, link)
    base.weaponType = SafeCall(GetItemLinkWeaponType, link)

    local eOk, hasCharges, enchantHeader, enchantDescription = LAC.SafeCallMulti(GetItemLinkEnchantInfo, link)
    if eOk then
        local header, description = NonEmpty(enchantHeader), NonEmpty(enchantDescription)
        base.enchant = {
            -- Jewelry enchants have no charges, so presence is judged by the header text.
            hasEnchant = header ~= nil or description ~= nil,
            hasCharges = hasCharges == true,
            name = header,
            description = description,
        }
    end

    return base
end

--- Compose gear triage fields on top of BagSlot.
--- Returns nil if slot empty. Always includes BagSlot identity + fields.
--- Non-gear items get the same shape with empty/false gear fields (no extra ZOS calls).
--- Fields: hasSet, set{hasSet,id,name,count,perfectedCount,max}, traitType, trait{id,name},
---         isIntricate, isOrnate, isResearchable, armorType, weaponType, canMarkJunk,
---         enchant{hasEnchant,hasCharges,name,description,charges,maxCharges}
--- canMarkJunk mirrors CanItemBeMarkedAsJunk (true even if already junk; see isJunk).
--- opts.equippedSetCounts — if true, GetItemLinkSetInfo(link, true) for worn counts.
function Gear.ComposeFromSlot(bagId, slotIndex, opts)
    opts = opts or {}
    local base = LAC.BagSlot.Compose(bagId, slotIndex, opts)
    if not base then
        return nil
    end
    enrich(base, opts)
    base.canMarkJunk = canMarkAsJunk(base)
    if base.enchant.hasCharges then
        local ok, charges, maxCharges = LAC.SafeCallMulti(GetChargeInfoForItem, bagId, slotIndex)
        if ok then
            base.enchant.charges = charges
            base.enchant.maxCharges = maxCharges
        end
    end
    return base
end

--- Compose gear triage fields on top of ItemLink.Compose (no bag slot needed).
--- Returns nil for an empty / non-item link. Same gear fields as ComposeFromSlot except the
--- slot-only ones: canMarkJunk, enchant.charges and enchant.maxCharges are absent.
function Gear.ComposeFromLink(link, opts)
    opts = opts or {}
    local base = LAC.ItemLink.Compose(link, opts)
    if not base then
        return nil
    end
    return enrich(base, opts)
end
