-- Minimal ESO API stubs for LibApiCompose unit tests.
-- Return shapes mirror the real ZOS signatures (see comments) so tests catch arity mistakes.

local M = {}

local items = {}
local bagSizes = {}
local collectibles = {}
local slots = {}
local companion = nil
local events = {}

function M.reset()
    items = {}
    bagSizes = {}
    collectibles = {}
    slots = {}
    companion = nil
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
_G.BAG_VIRTUAL = 5
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
_G.GAMEPLAY_ACTOR_CATEGORY_PLAYER = 0
_G.GAMEPLAY_ACTOR_CATEGORY_COMPANION = 1
_G.COLLECTIBLE_CATEGORY_TYPE_COMPANION = 27
_G.COLLECTIBLE_CATEGORY_TYPE_MOUNT = 2
_G.HOTBAR_CATEGORY_PRIMARY = 0
_G.HOTBAR_CATEGORY_BACKUP = 1
_G.HOTBAR_CATEGORY_QUICKSLOT_WHEEL = 7
_G.ACTION_TYPE_NOTHING = 0
_G.ACTION_TYPE_ITEM = 1
_G.ACTION_TYPE_COLLECTIBLE = 6
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

-- GetNextVirtualBagSlotId(lastSlotId|nil) -> nextSlotId|nil (craft bag: slotId == itemId)
function _G.GetNextVirtualBagSlotId(lastSlotId)
    local ids = {}
    for key in pairs(items) do
        local bag, slot = key:match("^(%d+):(%d+)$")
        if tonumber(bag) == BAG_VIRTUAL then
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

function _G.GetItemId(bagId, slotIndex)
    local it = itemAt(bagId, slotIndex)
    return it and it.id or 0
end

function _G.GetItemLink(bagId, slotIndex, _)
    local it = itemAt(bagId, slotIndex)
    return it and it.link or ""
end

function _G.GetItemType(bagId, slotIndex)
    local it = itemAt(bagId, slotIndex)
    return it and it.type or 0
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
function _G.GetSlotStackSize(bagId, slotIndex)
    local it = itemAt(bagId, slotIndex)
    if not it then
        return 0, 0
    end
    return it.stack or 1, it.maxStack or 1
end

-- GetItemInfo(bagId, slotIndex) -> icon, stack, sellPrice, meetsUsageRequirement,
--                                  locked, equipType, itemStyleId, displayQuality
function _G.GetItemInfo(bagId, slotIndex)
    local it = itemAt(bagId, slotIndex)
    if not it then
        return "", 0, 0, false, false, 0, 0, 0
    end
    return it.icon or "item.dds",
        it.stack or 1,
        it.sellPrice or 0,
        it.meetsUsage ~= false,
        it.locked == true,
        it.equipType or 0,
        0,
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
    return it and it.locked == true or false
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
function _G.GetItemLinkSetInfo(link, _)
    local it = itemByLink(link)
    if it then
        return it.hasSet or false, it.setName or "", 0, it.setCount or 0, it.setMax or 0, it.setId or 0, 0
    end
    return false, "", 0, 0, 0, 0, 0
end

-- GetItemLinkTraitType(link) -> traitType, traitDescription
function _G.GetItemLinkTraitType(link)
    local it = itemByLink(link)
    return it and it.traitType or 0, ""
end

-- GetItemLinkEnchantInfo(link) -> hasCharges, enchantHeader, enchantDescription
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
function _G.GetItemLinkOnUseAbilityInfo(link)
    if link == "|H0:item:1|h|h" then
        return true, "Header", "Description", 45000, false, 0, 0, false, 1000
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

-- Companion --------------------------------------------------------------

function _G.HasActiveCompanion()
    return companion ~= nil
end

function _G.GetActiveCompanionDefId()
    return companion and companion.defId or 0
end

function _G.GetCompanionCollectibleId(defId)
    if companion and companion.defId == defId then
        return companion.collectibleId
    end
    return 0
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

function _G.GetSlotTexture(slotIndex, hotbarCategory)
    local s = slotAt(slotIndex, hotbarCategory)
    return s and s.texture or ""
end

function _G.GetSlotItemCount(slotIndex, hotbarCategory)
    local s = slotAt(slotIndex, hotbarCategory)
    return s and s.count or 0
end

function _G.IsSlotUsable(slotIndex, hotbarCategory)
    local s = slotAt(slotIndex, hotbarCategory)
    return s and s.usable == true or false
end

return M
