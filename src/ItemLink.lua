-- LibApiCompose — ItemLink.Compose / ComposeOnUse (style C)
--
-- Link-based reads work anywhere an item link exists (loot, mail, guild store, chat) — no bag slot
-- required. BagSlot.Compose is the richer snapshot when you do have a slot.

local LAC = LibApiCompose
LAC.ItemLink = LAC.ItemLink or {}
local ItemLink = LAC.ItemLink
local SafeCall = LAC.SafeCall

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

-- Set-collection facts shared by ItemLink.Compose and BagSlot.Compose.
local function setCollectionFacts(link, itemId)
    local isPiece = SafeCall(IsItemLinkSetCollectionPiece, link) == true
    local isUnlocked = false
    if isPiece and itemId then
        isUnlocked = SafeCall(IsItemSetCollectionPieceUnlocked, itemId) == true
    end
    return isPiece, isUnlocked
end

LAC._internal.isGearType = isGearType
LAC._internal.isGlyphType = isGlyphType
LAC._internal.setCollectionFacts = setCollectionFacts

--- Item id embedded in an item link, parsed without a ZOS call. nil for non-item links.
function ItemLink.ParseId(link)
    if type(link) ~= "string" then
        return nil
    end
    return tonumber(link:match("|H%d:item:(%d+)"))
end

--- Compose an item link → fresh record, or nil for an empty / non-item link.
--- Identity: link, id
--- Fields: name?, type, specializedType, functionalQuality, displayQuality, icon, sellValue,
---         equipType, itemStyleId, meetsUsageRequirement, requiredLevel, requiredCP, bindType,
---         isBound, isStolen, isCrafted, isUnique, isCompanion, isGear, isGlyph,
---         isSetCollectionPiece, isSetCollectionUnlocked
--- opts.includeName — also fetch the formatted item name.
function ItemLink.Compose(link, opts)
    opts = opts or {}
    if type(link) ~= "string" or link == "" then
        return nil
    end
    local itemId = SafeCall(GetItemLinkItemId, link)
    if not itemId or itemId <= 0 then
        return nil
    end

    local typeOk, itemType, specializedType = LAC.SafeCallMulti(GetItemLinkItemType, link)
    if not typeOk then
        itemType, specializedType = nil, nil
    end
    local infoOk, icon, sellPrice, meetsUsage, equipType, itemStyleId = LAC.SafeCallMulti(GetItemLinkInfo, link)
    if not infoOk then
        icon, sellPrice, meetsUsage, equipType, itemStyleId = nil, nil, nil, nil, nil
    end

    local name = nil
    if opts.includeName then
        name = LAC.NonEmpty(LAC.FormatName(SafeCall(GetItemLinkName, link)))
    end

    local isPiece, isUnlocked = setCollectionFacts(link, itemId)
    local isCompanion = false
    if GAMEPLAY_ACTOR_CATEGORY_COMPANION ~= nil then
        isCompanion = SafeCall(GetItemLinkActorCategory, link) == GAMEPLAY_ACTOR_CATEGORY_COMPANION
    end

    return {
        link = link,
        id = itemId,
        name = name,
        type = itemType,
        specializedType = specializedType,
        functionalQuality = SafeCall(GetItemLinkFunctionalQuality, link),
        displayQuality = SafeCall(GetItemLinkDisplayQuality, link),
        icon = LAC.NonEmpty(icon),
        sellValue = sellPrice,
        equipType = equipType,
        itemStyleId = itemStyleId,
        meetsUsageRequirement = meetsUsage,
        requiredLevel = SafeCall(GetItemLinkRequiredLevel, link),
        requiredCP = SafeCall(GetItemLinkRequiredChampionPoints, link),
        bindType = SafeCall(GetItemLinkBindType, link),
        isBound = SafeCall(IsItemLinkBound, link) == true,
        isStolen = SafeCall(IsItemLinkStolen, link) == true,
        isCrafted = SafeCall(IsItemLinkCrafted, link) == true,
        isUnique = SafeCall(IsItemLinkUnique, link) == true,
        isCompanion = isCompanion,
        isGear = isGearType(itemType),
        isGlyph = isGlyphType(itemType),
        isSetCollectionPiece = isPiece,
        isSetCollectionUnlocked = isUnlocked,
    }
end

--- Compose consumable/on-use preview from an item link → fresh record, or nil for empty link.
--- Identity: link
--- Fields: icon, hasAbility, header, description, cooldown (ms), remainingCooldown (ms),
---         hasScaling, minLevel, maxLevel, isChampionPoints
--- Mirrors GetItemLinkOnUseAbilityInfo:
---   hasAbility, header, description, cooldown, hasScaling, minLevel, maxLevel, isCP, remainingCooldown
function ItemLink.ComposeOnUse(link)
    if type(link) ~= "string" or link == "" then
        return nil
    end

    local ok, aHas, aHeader, aDesc, aCooldown, aScaling, aMin, aMax, aIsCP, aRemaining =
        LAC.SafeCallMulti(GetItemLinkOnUseAbilityInfo, link)
    if not ok then
        aHas, aHeader, aDesc, aCooldown, aScaling, aMin, aMax, aIsCP, aRemaining =
            nil, nil, nil, nil, nil, nil, nil, nil, nil
    end

    return {
        link = link,
        icon = LAC.NonEmpty(SafeCall(GetItemLinkIcon, link)),
        hasAbility = aHas == true,
        header = LAC.NonEmpty(aHeader),
        description = LAC.NonEmpty(aDesc),
        cooldown = aCooldown,
        remainingCooldown = aRemaining,
        hasScaling = aScaling == true,
        minLevel = aMin,
        maxLevel = aMax,
        isChampionPoints = aIsCP == true,
    }
end
