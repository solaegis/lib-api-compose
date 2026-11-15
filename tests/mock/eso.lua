-- Minimal ESO API stubs for LibApiCompose unit tests.
-- Return shapes mirror the real ZOS signatures (see comments) so tests catch arity mistakes.

local M = {}

local items = {}
local bagSizes = {}
local collectibles = {}
local slots = {}
local companion = nil
local pendingCompanion = nil
local units = {}
local currencies = {}
local skills = {}
local buffs = {}
local currentQuickslot = 0
local activeHotbar = 0
local events = {}

function M.reset()
    items = {}
    bagSizes = {}
    collectibles = {}
    slots = {}
    companion = nil
    pendingCompanion = nil
    units = {}
    currencies = {}
    skills = {}
    buffs = {}
    currentQuickslot = 0
    activeHotbar = 0
    if LibApiCompose and LibApiCompose.ClearCache then
        LibApiCompose.ClearCache()
    end
end

function M.setItem(bagId, slotIndex, data)
    items[bagId .. ":" .. slotIndex] = data
end

function M.setBagSize(bagId, size)
    bagSizes[bagId] = size
end

function M.setCollectible(id, data)
    collectibles[id] = data
end

function M.setSlot(hotbarCategory, slotIndex, data)
    slots[hotbarCategory .. ":" .. slotIndex] = data
end

function M.setCompanion(data)
    companion = data
end

function M.setPendingCompanion(data)
    pendingCompanion = data
end

--- data: { name, level, cp, classId, className, raceId, raceName, alliance, dead, combat, powers = { [type] = {cur, max, eff} } }
function M.setUnit(unitTag, data)
    units[unitTag] = data
end

function M.setCurrency(currencyType, location, amount)
    currencies[currencyType .. ":" .. location] = amount
end

--- tree: { [skillType] = { { id, name, rank, abilities = { { id, name, passive, ... } } } } }
function M.setSkills(tree)
    skills = tree
end

--- list: array of { name, started, ending, stacks, effectType, abilityId, ... }
function M.setBuffs(unitTag, list)
    buffs[unitTag] = list
end

function M.setCurrentQuickslot(slotIndex)
    currentQuickslot = slotIndex
end

function M.setActiveHotbar(hotbarCategory)
    activeHotbar = hotbarCategory
end

--- Fire every handler registered for eventCode (as EVENT_MANAGER would).
function M.fireEvent(eventCode, ...)
    for _, reg in ipairs(events) do
        if reg.event == eventCode then
            reg.fn(eventCode, ...)
        end
    end
end

function M.registeredEvents()
    return events
end

local function itemAt(bagId, slotIndex)
    return items[bagId .. ":" .. slotIndex]
end

local function itemByLink(link)
    for _, it in pairs(items) do
        if it.link == link then
            return it
        end
    end
    return nil
end

local function slotAt(slotIndex, hotbarCategory)
    return slots[hotbarCategory .. ":" .. slotIndex]
end

-- Constants -------------------------------------------------------------

_G.BAG_WORN = 0
_G.BAG_BACKPACK = 1
_G.BAG_BANK = 2
_G.BAG_GUILDBANK = 3
_G.BAG_VIRTUAL = 5
_G.BAG_SUBSCRIBER_BANK = 6
_G.BAG_HOUSE_BANK_ONE = 7
_G.BAG_HOUSE_BANK_TWO = 8
_G.BAG_COMPANION_WORN = 17
_G.LINK_STYLE_DEFAULT = 0
_G.ITEMTYPE_WEAPON = 1
_G.ITEMTYPE_ARMOR = 2
_G.ITEMTYPE_GLYPH_ARMOR = 3
_G.ITEMTYPE_GLYPH_JEWELRY = 4
_G.ITEMTYPE_GLYPH_WEAPON = 5
_G.ITEMTYPE_POTION = 6
_G.ITEM_TRAIT_TYPE_NONE = 0
_G.ITEM_TRAIT_TYPE_WEAPON_INTRICATE = 10
_G.ITEM_TRAIT_TYPE_ARMOR_INTRICATE = 11
_G.ITEM_TRAIT_TYPE_JEWELRY_INTRICATE = 12
_G.ITEM_TRAIT_TYPE_WEAPON_ORNATE = 13
_G.ITEM_TRAIT_TYPE_ARMOR_ORNATE = 14
_G.ITEM_TRAIT_TYPE_JEWELRY_ORNATE = 15
_G.GAMEPLAY_ACTOR_CATEGORY_PLAYER = 0
_G.GAMEPLAY_ACTOR_CATEGORY_COMPANION = 1
_G.COLLECTIBLE_CATEGORY_TYPE_INVALID = 0
_G.COLLECTIBLE_CATEGORY_TYPE_COMPANION = 27
_G.COLLECTIBLE_CATEGORY_TYPE_MOUNT = 2
_G.HOTBAR_CATEGORY_PRIMARY = 0
_G.HOTBAR_CATEGORY_BACKUP = 1
_G.HOTBAR_CATEGORY_QUICKSLOT_WHEEL = 7
_G.HOTBAR_CATEGORY_ALLY_WHEEL = 8
_G.HOTBAR_CATEGORY_EMOTE_WHEEL = 9
_G.HOTBAR_CATEGORY_MEMENTO_WHEEL = 10
_G.HOTBAR_CATEGORY_TOOL_WHEEL = 11
_G.ACTION_BAR_FIRST_NORMAL_SLOT_INDEX = 2
_G.ACTION_BAR_ULTIMATE_SLOT_INDEX = 7
_G.ACTION_BAR_UTILITY_BAR_SIZE = 8
_G.ACTION_TYPE_NOTHING = 0
_G.ACTION_TYPE_ITEM = 1
_G.ACTION_TYPE_ABILITY = 2
_G.ACTION_TYPE_COLLECTIBLE = 6
_G.ACTION_TYPE_CRAFTED_ABILITY = 9
_G.COMBAT_MECHANIC_FLAGS_HEALTH = 32
_G.COMBAT_MECHANIC_FLAGS_MAGICKA = 1
_G.COMBAT_MECHANIC_FLAGS_STAMINA = 4
_G.CURT_MONEY = 1
_G.CURT_ALLIANCE_POINTS = 2
_G.CURT_TELVAR_STONES = 3
_G.CURT_WRIT_VOUCHERS = 4
_G.CURT_CROWNS = 8
_G.CURRENCY_LOCATION_CHARACTER = 0
_G.CURRENCY_LOCATION_BANK = 1
_G.CURRENCY_LOCATION_ACCOUNT = 3
_G.BUFF_EFFECT_TYPE_BUFF = 1
_G.BUFF_EFFECT_TYPE_DEBUFF = 2
_G.EVENT_COLLECTION_UPDATED = 9000
_G.EVENT_COLLECTIBLES_UNLOCK_STATE_CHANGED = 9001
_G.EVENT_COLLECTIBLE_UPDATED = 9002

-- EVENT_MANAGER ----------------------------------------------------------

_G.EVENT_MANAGER = {
    RegisterForEvent = function(_, namespace, eventCode, fn)
        events[#events + 1] = { namespace = namespace, event = eventCode, fn = fn }
        return true
    end,
}

-- Bag / item -------------------------------------------------------------

function _G.GetBagSize(bagId)
    return bagSizes[bagId] or 0
end

local function nextLinkedSlot(bagId, lastSlotId)
    local ids = {}
    for key in pairs(items) do
        local bag, slot = key:match("^(%d+):(%d+)$")
        if tonumber(bag) == bagId then
            ids[#ids + 1] = tonumber(slot)
        end
    end
    table.sort(ids)
    for _, id in ipairs(ids) do
        if lastSlotId == nil or id > lastSlotId then
            return id
        end
    end
    return nil
end

-- GetNextVirtualBagSlotId(lastSlotId|nil) -> nextSlotId|nil (craft bag: slotId == itemId)
function _G.GetNextVirtualBagSlotId(lastSlotId)
    return nextLinkedSlot(BAG_VIRTUAL, lastSlotId)
end

-- GetNextGuildBankSlotId(lastSlotId|nil) -> nextSlotId|nil
function _G.GetNextGuildBankSlotId(lastSlotId)
    return nextLinkedSlot(BAG_GUILDBANK, lastSlotId)
end

function _G.GetItemId(bagId, slotIndex)
    local it = itemAt(bagId, slotIndex)
    return it and it.id or 0
end

function _G.GetItemLink(bagId, slotIndex, _)
    local it = itemAt(bagId, slotIndex)
    return it and it.link or ""
end

-- returns: 2
function _G.GetItemType(bagId, slotIndex)
    local it = itemAt(bagId, slotIndex)
    if not it then
        return 0, 0
    end
    return it.type or 0, it.specializedType or 0
end

function _G.GetItemName(bagId, slotIndex)
    local it = itemAt(bagId, slotIndex)
    return it and it.name or ""
end

function _G.GetItemFunctionalQuality(bagId, slotIndex)
    local it = itemAt(bagId, slotIndex)
    return it and it.quality or 0
end

function _G.GetItemDisplayQuality(bagId, slotIndex)
    local it = itemAt(bagId, slotIndex)
    return it and (it.displayQuality or it.quality) or 0
end

-- GetSlotStackSize(bagId, slotIndex) -> stackSize, maxStackSize
-- returns: 2
function _G.GetSlotStackSize(bagId, slotIndex)
    local it = itemAt(bagId, slotIndex)
    if not it then
        return 0, 0
    end
    return it.stack or 1, it.maxStack or 1
end

-- GetItemInfo(bagId, slotIndex) -> icon, stack, sellPrice, meetsUsageRequirement, locked,
--     equipType, itemStyleId, functionalQuality, displayQuality
-- `locked` is the transient slot lock (data.slotLocked); the player lock is IsItemPlayerLocked.
-- returns: 9
function _G.GetItemInfo(bagId, slotIndex)
    local it = itemAt(bagId, slotIndex)
    if not it then
        return "", 0, 0, false, false, 0, 0, 0, 0
    end
    return it.icon or "item.dds",
        it.stack or 1,
        it.sellPrice or 0,
        it.meetsUsage ~= false,
        it.slotLocked == true,
        it.equipType or 0,
        it.styleId or 0,
        it.quality or 0,
        it.displayQuality or it.quality or 0
end

function _G.GetItemActorCategory(bagId, slotIndex)
    local it = itemAt(bagId, slotIndex)
    return it and (it.actorCategory or 0) or 0
end

function _G.GetItemUniqueId(bagId, slotIndex)
    local it = itemAt(bagId, slotIndex)
    return it and it.uniqueId or nil
end

function _G.Id64ToString(id)
    return tostring(id)
end

function _G.GetItemRequiredLevel(bagId, slotIndex)
    local it = itemAt(bagId, slotIndex)
    return it and (it.reqLevel or 1) or 0
end

function _G.GetItemRequiredChampionPoints(bagId, slotIndex)
    local it = itemAt(bagId, slotIndex)
    return it and (it.reqCP or 0) or 0
end

function _G.IsItemJunk(bagId, slotIndex)
    local it = itemAt(bagId, slotIndex)
    return it and it.junk == true or false
end

function _G.IsItemPlayerLocked(bagId, slotIndex)
    local it = itemAt(bagId, slotIndex)
    return it and it.playerLocked == true or false
end

function _G.GetItemBindType(bagId, slotIndex)
    local it = itemAt(bagId, slotIndex)
    return it and it.bindType or 0
end

function _G.GetItemCondition(bagId, slotIndex)
    local it = itemAt(bagId, slotIndex)
    return it and it.condition or 100
end

function _G.GetItemCreatorName(bagId, slotIndex)
    local it = itemAt(bagId, slotIndex)
    return it and it.creator or ""
end

function _G.IsItemInArmory(bagId, slotIndex)
    local it = itemAt(bagId, slotIndex)
    return it and it.inArmory == true or false
end

-- returns: 2
function _G.IsItemUsable(bagId, slotIndex)
    local it = itemAt(bagId, slotIndex)
    return it and it.usable == true or false, false
end

-- returns: 2
function _G.GetChargeInfoForItem(bagId, slotIndex)
    local it = itemAt(bagId, slotIndex)
    if not it then
        return 0, 0
    end
    return it.charges or 0, it.maxCharges or 0
end

function _G.IsItemBound(bagId, slotIndex)
    local it = itemAt(bagId, slotIndex)
    return it and it.bound == true or false
end

function _G.IsItemStolen(bagId, slotIndex)
    local it = itemAt(bagId, slotIndex)
    return it and it.stolen == true or false
end

function _G.CanItemBeMarkedAsJunk(bagId, slotIndex)
    local it = itemAt(bagId, slotIndex)
    if not it then
        return false
    end
    return it.canJunk ~= false
end

-- Item link --------------------------------------------------------------

-- GetItemLinkSetInfo(link, equipped) -> hasSet, setName, numBonuses, numNormalEquipped,
--                                       maxEquipped, setId, numPerfectedEquipped
-- returns: 7
function _G.GetItemLinkSetInfo(link, _)
    local it = itemByLink(link)
    if it then
        return it.hasSet or false, it.setName or "", 0, it.setCount or 0, it.setMax or 0, it.setId or 0, 0
    end
    return false, "", 0, 0, 0, 0, 0
end

function _G.GetItemLinkTraitType(link)
    local it = itemByLink(link)
    return it and it.traitType or 0
end

function _G.GetItemLinkItemId(link)
    local it = itemByLink(link)
    return it and it.id or 0
end

-- returns: 2
function _G.GetItemLinkItemType(link)
    local it = itemByLink(link)
    if not it then
        return 0, 0
    end
    return it.type or 0, it.specializedType or 0
end

-- GetItemLinkInfo(link) -> icon, sellPrice, meetsUsageRequirement, equipType, itemStyleId
-- returns: 5
function _G.GetItemLinkInfo(link)
    local it = itemByLink(link)
    if not it then
        return "", 0, false, 0, 0
    end
    return it.icon or "item.dds", it.sellPrice or 0, it.meetsUsage ~= false, it.equipType or 0, it.styleId or 0
end

function _G.GetItemLinkName(link)
    local it = itemByLink(link)
    return it and it.name or ""
end

function _G.GetItemLinkFunctionalQuality(link)
    local it = itemByLink(link)
    return it and it.quality or 0
end

function _G.GetItemLinkDisplayQuality(link)
    local it = itemByLink(link)
    return it and (it.displayQuality or it.quality) or 0
end

function _G.GetItemLinkRequiredLevel(link)
    local it = itemByLink(link)
    return it and (it.reqLevel or 1) or 0
end

function _G.GetItemLinkRequiredChampionPoints(link)
    local it = itemByLink(link)
    return it and (it.reqCP or 0) or 0
end

function _G.GetItemLinkBindType(link)
    local it = itemByLink(link)
    return it and it.bindType or 0
end

function _G.IsItemLinkBound(link)
    local it = itemByLink(link)
    return it and it.bound == true or false
end

function _G.IsItemLinkStolen(link)
    local it = itemByLink(link)
    return it and it.stolen == true or false
end

function _G.IsItemLinkCrafted(link)
    local it = itemByLink(link)
    return it and it.crafted == true or false
end

function _G.IsItemLinkUnique(link)
    local it = itemByLink(link)
    return it and it.unique == true or false
end

function _G.GetItemLinkActorCategory(link)
    local it = itemByLink(link)
    return it and (it.actorCategory or 0) or 0
end

function _G.IsItemLinkSetCollectionPiece(link)
    local it = itemByLink(link)
    return it and it.setPiece == true or false
end

function _G.IsItemSetCollectionPieceUnlocked(pieceId)
    for _, it in pairs(items) do
        if it.id == pieceId then
            return it.setPieceUnlocked == true
        end
    end
    return false
end

function _G.GetItemLinkArmorType(link)
    local it = itemByLink(link)
    return it and it.armorType or 0
end

function _G.GetItemLinkWeaponType(link)
    local it = itemByLink(link)
    return it and it.weaponType or 0
end

-- GetItemLinkEnchantInfo(link) -> hasCharges, enchantHeader, enchantDescription
-- returns: 3
function _G.GetItemLinkEnchantInfo(link)
    local it = itemByLink(link)
    if it then
        return it.hasCharges == true, it.enchantHeader or "", it.enchantDesc or ""
    end
    return false, "", ""
end

function _G.CanItemLinkBeTraitResearched(link)
    local it = itemByLink(link)
    return it and it.researchable == true or false
end

function _G.GetItemLinkIcon(_)
    return "icon.dds"
end

-- GetItemLinkOnUseAbilityInfo(link) -> hasAbility, abilityHeader, abilityDescription, cooldown,
--     hasScaling, minLevel, maxLevel, isChampionPoints, remainingCooldown
-- returns: 9
function _G.GetItemLinkOnUseAbilityInfo(link)
    if link == "|H0:item:1|h|h" then
        return true, "Header", "Description", 45000, true, 10, 50, false, 1000
    end
    return false, "", "", 0, false, 0, 0, false, 0
end

function _G.GetString(prefix, id)
    return tostring(prefix) .. "_" .. tostring(id)
end

-- Collectibles -----------------------------------------------------------

local function idsInCategory(categoryType)
    local ids = {}
    for id, c in pairs(collectibles) do
        if c.category == categoryType then
            ids[#ids + 1] = id
        end
    end
    table.sort(ids)
    return ids
end

function _G.GetTotalCollectiblesByCategoryType(categoryType)
    return #idsInCategory(categoryType)
end

function _G.GetCollectibleIdFromType(categoryType, index)
    return idsInCategory(categoryType)[index] or 0
end

function _G.GetCollectibleName(id)
    local c = collectibles[id]
    return c and c.name or ""
end

-- GetCollectibleInfo(id) -> name, description, icon, deprecatedLockedIcon, unlocked,
--     purchasable, isActive, categoryType, hint
-- returns: 9
function _G.GetCollectibleInfo(id)
    local c = collectibles[id]
    if not c then
        return "", "", "", "", false, false, false, 0, ""
    end
    return c.infoName or c.name or "",
        c.description or "",
        c.icon or "",
        "",
        c.unlocked == true,
        false,
        c.active == true,
        c.category or 0,
        ""
end

function _G.GetCollectibleNickname(id)
    local c = collectibles[id]
    return c and c.nickname or ""
end

function _G.GetCollectibleIcon(id)
    local c = collectibles[id]
    return c and c.icon or ""
end

function _G.GetCollectibleCategoryType(id)
    local c = collectibles[id]
    return c and c.category or 0
end

function _G.IsCollectibleUnlocked(id)
    local c = collectibles[id]
    return c and c.unlocked == true or false
end

function _G.IsCollectibleActive(id, _)
    local c = collectibles[id]
    return c and c.active == true or false
end

function _G.GetCollectibleUnlockStateById(id)
    local c = collectibles[id]
    return c and (c.unlockState or (c.unlocked and 1 or 0)) or 0
end

function _G.IsCollectibleBlocked(id, _)
    local c = collectibles[id]
    return c and c.blocked == true or false
end

-- returns: 2
function _G.GetCollectibleCooldownAndDuration(id)
    local c = collectibles[id]
    if not c then
        return 0, 0
    end
    return c.cooldownRemaining or 0, c.cooldownDuration or 0
end

function _G.GetCollectibleDescription(id)
    local c = collectibles[id]
    return c and c.description or ""
end

function _G.GetCollectibleLink(id, _)
    return collectibles[id] and ("|H0:collectible:" .. id .. "|h|h") or ""
end

function _G.GetActiveCollectibleByType(categoryType, _)
    for id, c in pairs(collectibles) do
        if c.category == categoryType and c.active then
            return id
        end
    end
    return 0
end

-- Companion --------------------------------------------------------------

function _G.HasActiveCompanion()
    return companion ~= nil
end

function _G.GetActiveCompanionDefId()
    return companion and companion.defId or 0
end

function _G.GetCompanionCollectibleId(defId)
    for _, c in ipairs({ companion or false, pendingCompanion or false }) do
        if c and c.defId == defId then
            return c.collectibleId or 0
        end
    end
    return 0
end

function _G.GetCompanionName(defId)
    for _, c in ipairs({ companion or false, pendingCompanion or false }) do
        if c and c.defId == defId then
            return c.name or ""
        end
    end
    return ""
end

-- returns: 2
function _G.GetActiveCompanionLevelInfo()
    if not companion then
        return 0, 0
    end
    return companion.level or 1, companion.xp or 0
end

function _G.GetActiveCompanionRapport()
    return companion and companion.rapport or 0
end

function _G.GetActiveCompanionRapportLevel()
    return companion and companion.rapportLevel or 0
end

function _G.HasPendingCompanion()
    return pendingCompanion ~= nil
end

function _G.GetPendingCompanionDefId()
    return pendingCompanion and pendingCompanion.defId or 0
end

-- Action slots -----------------------------------------------------------

function _G.GetSlotType(slotIndex, hotbarCategory)
    local s = slotAt(slotIndex, hotbarCategory)
    return s and s.type or ACTION_TYPE_NOTHING
end

function _G.GetSlotBoundId(slotIndex, hotbarCategory)
    local s = slotAt(slotIndex, hotbarCategory)
    return s and s.id or 0
end

function _G.GetSlotName(slotIndex, hotbarCategory)
    local s = slotAt(slotIndex, hotbarCategory)
    return s and s.name or ""
end

-- returns: 3
function _G.GetSlotTexture(slotIndex, hotbarCategory)
    local s = slotAt(slotIndex, hotbarCategory)
    return s and s.texture or "", "", ""
end

-- GetSlotCooldownInfo(slot, hotbar) -> remain, duration, global, globalSlotType
-- returns: 4
function _G.GetSlotCooldownInfo(slotIndex, hotbarCategory)
    local s = slotAt(slotIndex, hotbarCategory)
    if not s then
        return 0, 0, false, 0
    end
    return s.cooldownRemaining or 0, s.cooldownDuration or 0, false, 0
end

function _G.GetSlotItemLink(slotIndex, hotbarCategory)
    local s = slotAt(slotIndex, hotbarCategory)
    return s and s.itemLink or ""
end

function _G.GetCurrentQuickslot()
    return currentQuickslot
end

function _G.GetActiveHotbarCategory()
    return activeHotbar
end

function _G.GetAbilityIdForCraftedAbilityId(craftedAbilityId)
    return craftedAbilityId + 100000
end

function _G.GetSlotItemCount(slotIndex, hotbarCategory)
    local s = slotAt(slotIndex, hotbarCategory)
    return s and s.count or 0
end

function _G.IsSlotUsable(slotIndex, hotbarCategory)
    local s = slotAt(slotIndex, hotbarCategory)
    return s and s.usable == true or false
end

-- Units ------------------------------------------------------------------

local function unitField(unitTag, field, default)
    local u = units[unitTag]
    if u and u[field] ~= nil then
        return u[field]
    end
    return default
end

function _G.DoesUnitExist(unitTag)
    return units[unitTag] ~= nil
end

function _G.GetUnitName(unitTag)
    return unitField(unitTag, "name", "")
end

function _G.GetUnitDisplayName(unitTag)
    return unitField(unitTag, "displayName", "")
end

function _G.GetUnitLevel(unitTag)
    return unitField(unitTag, "level", 0)
end

function _G.GetUnitChampionPoints(unitTag)
    return unitField(unitTag, "cp", 0)
end

function _G.GetUnitEffectiveChampionPoints(unitTag)
    return unitField(unitTag, "effectiveCp", unitField(unitTag, "cp", 0))
end

function _G.GetUnitClassId(unitTag)
    return unitField(unitTag, "classId", 0)
end

function _G.GetUnitClass(unitTag)
    return unitField(unitTag, "className", "")
end

function _G.GetUnitRaceId(unitTag)
    return unitField(unitTag, "raceId", 0)
end

function _G.GetUnitRace(unitTag)
    return unitField(unitTag, "raceName", "")
end

function _G.GetUnitAlliance(unitTag)
    return unitField(unitTag, "alliance", 0)
end

function _G.GetAllianceName(alliance)
    return "Alliance" .. tostring(alliance) .. "^N"
end

function _G.GetUnitGender(unitTag)
    return unitField(unitTag, "gender", 0)
end

function _G.GetUnitZone(unitTag)
    return unitField(unitTag, "zone", "")
end

function _G.IsUnitPlayer(unitTag)
    return unitField(unitTag, "isPlayer", false)
end

function _G.IsUnitDead(unitTag)
    return unitField(unitTag, "dead", false)
end

function _G.IsUnitInCombat(unitTag)
    return unitField(unitTag, "combat", false)
end

function _G.IsUnitOnline(unitTag)
    return unitField(unitTag, "online", true)
end

-- GetUnitPower(unitTag, powerType) -> current, max, effectiveMax
-- returns: 3
function _G.GetUnitPower(unitTag, powerType)
    local p = unitField(unitTag, "powers", {})[powerType]
    if not p then
        return 0, 0, 0
    end
    return p[1], p[2], p[3]
end

-- Currency ---------------------------------------------------------------

function _G.IsCurrencyValid(currencyType)
    return type(currencyType) == "number" and currencyType > 0 and currencyType < 100
end

function _G.GetCurrencyAmount(currencyType, location)
    return currencies[currencyType .. ":" .. location] or 0
end

function _G.GetMaxPossibleCurrency(_, _)
    return 2100000000
end

function _G.GetCurrencyName(currencyType, _, _)
    return "Currency" .. tostring(currencyType) .. "^n"
end

-- returns: 2
function _G.GetCurrencyKeyboardIcon(currencyType)
    return "currency" .. tostring(currencyType) .. ".dds", 100
end

-- Crowns are account-wide; everything else lives on the character or in the bank.
function _G.CanCurrencyBeStoredInLocation(currencyType, location)
    if currencyType == CURT_CROWNS then
        return location == CURRENCY_LOCATION_ACCOUNT
    end
    return location ~= CURRENCY_LOCATION_ACCOUNT
end

-- Skills -----------------------------------------------------------------

local function skillLine(skillType, lineIndex)
    return skills[skillType] and skills[skillType][lineIndex] or nil
end

local function skillAbility(skillType, lineIndex, abilityIndex)
    local line = skillLine(skillType, lineIndex)
    return line and line.abilities and line.abilities[abilityIndex] or nil
end

function _G.GetNumSkillTypes()
    local n = 0
    for skillType in pairs(skills) do
        if skillType > n then
            n = skillType
        end
    end
    return n
end

function _G.GetNumSkillLines(skillType)
    return skills[skillType] and #skills[skillType] or 0
end

function _G.GetNumSkillAbilities(skillType, lineIndex)
    local line = skillLine(skillType, lineIndex)
    return line and line.abilities and #line.abilities or 0
end

function _G.GetSkillLineId(skillType, lineIndex)
    local line = skillLine(skillType, lineIndex)
    return line and line.id or 0
end

function _G.GetSkillLineNameById(lineId)
    for _, lines in pairs(skills) do
        for _, line in ipairs(lines) do
            if line.id == lineId then
                return line.name or ""
            end
        end
    end
    return ""
end

-- GetSkillLineDynamicInfo -> rank, isAdvised, isActive, isDiscovered, isAccountSkill,
--     isInTraining, isClassMastery
-- returns: 7
function _G.GetSkillLineDynamicInfo(skillType, lineIndex)
    local line = skillLine(skillType, lineIndex)
    if not line then
        return 0, false, false, false, false, false, false
    end
    return line.rank or 1, false, line.active ~= false, line.discovered ~= false, false, false, false
end

-- returns: 3
function _G.GetSkillLineXPInfo(skillType, lineIndex)
    local line = skillLine(skillType, lineIndex)
    if not line then
        return 0, 0, 0
    end
    return 0, line.nextXP or 100, line.xp or 0
end

-- GetSkillAbilityInfo -> name, texture, earnedRank, passive, ultimate, purchased,
--     progressionIndex, rank
-- returns: 8
function _G.GetSkillAbilityInfo(skillType, lineIndex, abilityIndex)
    local a = skillAbility(skillType, lineIndex, abilityIndex)
    if not a then
        return "", "", 0, false, false, false, nil, 0
    end
    return a.name or "",
        a.icon or "skill.dds",
        a.earnedRank or 1,
        a.passive == true,
        a.ultimate == true,
        a.purchased == true,
        a.progressionIndex,
        a.rank or 1
end

function _G.GetSkillAbilityId(skillType, lineIndex, abilityIndex, _)
    local a = skillAbility(skillType, lineIndex, abilityIndex)
    return a and a.id or 0
end

-- returns: 2
function _G.GetSkillAbilityUpgradeInfo(skillType, lineIndex, abilityIndex)
    local a = skillAbility(skillType, lineIndex, abilityIndex)
    if not a or not a.passive then
        return nil, nil
    end
    return a.upgradeLevel or 1, a.maxUpgradeLevel or 2
end

function _G.IsCraftedAbilitySkill(skillType, lineIndex, abilityIndex)
    local a = skillAbility(skillType, lineIndex, abilityIndex)
    return a and a.craftedId ~= nil or false
end

function _G.GetCraftedAbilitySkillCraftedAbilityId(skillType, lineIndex, abilityIndex)
    local a = skillAbility(skillType, lineIndex, abilityIndex)
    return a and a.craftedId or 0
end

-- Buffs ------------------------------------------------------------------

function _G.GetNumBuffs(unitTag)
    return buffs[unitTag] and #buffs[unitTag] or 0
end

-- GetUnitBuffInfo(unitTag, index) -> buffName, timeStarted, timeEnding, buffSlot, stackCount,
--     iconFilename, deprecatedBuffType, effectType, abilityType, statusEffectType, abilityId,
--     canClickOff, castByPlayer
-- returns: 13
function _G.GetUnitBuffInfo(unitTag, index)
    local b = buffs[unitTag] and buffs[unitTag][index]
    if not b then
        error("invalid buff index")
    end
    return b.name or "",
        b.started or 0,
        b.ending or 0,
        b.slot or index,
        b.stacks or 1,
        b.icon or "buff.dds",
        "",
        b.effectType or BUFF_EFFECT_TYPE_BUFF,
        b.abilityType or 0,
        b.statusEffectType or 0,
        b.abilityId or 0,
        b.canClickOff == true,
        b.castByPlayer == true
end

return M
