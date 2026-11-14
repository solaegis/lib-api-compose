-- Minimal ESO API stubs for LibApiCompose unit tests.

local M = {}

local items = {}
local collectibles = {}

function M.reset()
    items = {}
    collectibles = {}
end

function M.setItem(bagId, slotIndex, data)
    items[bagId .. ":" .. slotIndex] = data
end

function M.setCollectible(id, data)
    collectibles[id] = data
end

local function itemAt(bagId, slotIndex)
    return items[bagId .. ":" .. slotIndex]
end

_G.LINK_STYLE_DEFAULT = 0
_G.ITEMTYPE_WEAPON = 1
_G.ITEMTYPE_ARMOR = 2
_G.ITEMTYPE_GLYPH_ARMOR = 3
_G.ITEMTYPE_GLYPH_JEWELRY = 4
_G.ITEMTYPE_GLYPH_WEAPON = 5
_G.ITEM_TRAIT_TYPE_NONE = 0
_G.ITEM_TRAIT_TYPE_WEAPON_INTRICATE = 10
_G.ITEM_TRAIT_TYPE_ARMOR_INTRICATE = 11
_G.ITEM_TRAIT_TYPE_JEWELRY_INTRICATE = 12
_G.GAMEPLAY_ACTOR_CATEGORY_PLAYER = 0
_G.GAMEPLAY_ACTOR_CATEGORY_COMPANION = 1
_G.COLLECTIBLE_CATEGORY_TYPE_COMPANION = 27
_G.HOTBAR_CATEGORY_PRIMARY = 0
_G.HOTBAR_CATEGORY_BACKUP = 1
_G.HOTBAR_CATEGORY_QUICKSLOT_WHEEL = 7
_G.ACTION_TYPE_COLLECTIBLE = 6
_G.QUALITY_SUPERIOR = 3

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
    return it and it.name or nil
end

function _G.GetItemFunctionalQuality(bagId, slotIndex)
    local it = itemAt(bagId, slotIndex)
    return it and it.quality or nil
end

function _G.GetSlotStackSize(bagId, slotIndex)
    local it = itemAt(bagId, slotIndex)
    return it and (it.stack or 1) or 0
end

function _G.GetItemActorCategory(bagId, slotIndex)
    local it = itemAt(bagId, slotIndex)
    return it and (it.actorCategory or 0) or 0
end

function _G.GetItemLinkSetInfo(link, _)
    for _, it in pairs(items) do
        if it.link == link then
            return it.hasSet or false, it.setName, 0, it.setCount or 0, it.setMax or 0, it.setId
        end
    end
    return false, nil, 0, 0, 0, nil
end

function _G.GetItemLinkTraitType(link)
    for _, it in pairs(items) do
        if it.link == link then
            return it.traitType or 0
        end
    end
    return 0
end

function _G.GetItemLinkEnchantInfo(link)
    for _, it in pairs(items) do
        if it.link == link then
            return it.hasEnchant or false, it.enchantHeader, it.enchantDesc
        end
    end
    return false, nil, nil
end

function _G.CanItemLinkBeTraitResearched(link)
    for _, it in pairs(items) do
        if it.link == link then
            return it.researchable == true
        end
    end
    return false
end

function _G.CanItemBeMarkedAsJunk(bagId, slotIndex)
    local it = itemAt(bagId, slotIndex)
    if not it then
        return false
    end
    if it.canJunk == false then
        return false
    end
    return true
end

function _G.GetCollectibleName(id)
    local c = collectibles[id]
    return c and c.name or nil
end

function _G.GetCollectibleIcon(id)
    local c = collectibles[id]
    return c and c.icon or nil
end

function _G.GetCollectibleCategoryType(id)
    local c = collectibles[id]
    return c and c.category or nil
end

function _G.IsCollectibleUnlocked(id)
    local c = collectibles[id]
    return c and c.unlocked == true
end

function _G.IsCollectibleActive(id, _)
    local c = collectibles[id]
    return c and c.active == true
end

function _G.GetItemLinkIcon(link)
    return "icon.dds"
end

function _G.GetItemLinkOnUseAbilityInfo(link)
    return 12345, "Header", "Description"
end

return M
