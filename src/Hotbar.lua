-- LibApiCompose — Hotbar.ComposeSlot / ComposeBar (style E): skill bars
--
-- Skill bar slots are 1-based action slot indices: abilities FIRST_SLOT..LAST_SLOT, ultimate
-- ULTIMATE_SLOT (3..7 and 8 on current clients). Utility wheels live in Quickslot.lua.

local LAC = LibApiCompose
LAC.Hotbar = LAC.Hotbar or {}
local Hotbar = LAC.Hotbar
local SafeCall = LAC.SafeCall
local NonEmpty = LAC.NonEmpty

Hotbar.FIRST_SLOT = (type(ACTION_BAR_FIRST_NORMAL_SLOT_INDEX) == "number" and ACTION_BAR_FIRST_NORMAL_SLOT_INDEX or 2)
    + 1
Hotbar.ULTIMATE_SLOT = (type(ACTION_BAR_ULTIMATE_SLOT_INDEX) == "number" and ACTION_BAR_ULTIMATE_SLOT_INDEX or 7) + 1
Hotbar.LAST_SLOT = Hotbar.ULTIMATE_SLOT - 1

local function activeHotbar()
    return SafeCall(GetActiveHotbarCategory) or HOTBAR_CATEGORY_PRIMARY
end

--- Compose a skill-bar slot → fresh record (always returned; check isEmpty).
--- Identity: hotbarCategory, slotIndex, actionType, actionId
--- Fields: isEmpty, isUltimate, abilityId, craftedAbilityId, name, icon, usable,
---         cooldownRemaining (ms), cooldownDuration (ms)
--- abilityId is the castable ability: for scribed skills (ACTION_TYPE_CRAFTED_ABILITY) it is
--- resolved from the crafted ability id, which stays available as craftedAbilityId.
--- hotbarCategory defaults to the active bar.
function Hotbar.ComposeSlot(slotIndex, hotbarCategory)
    if slotIndex == nil then
        return nil
    end
    hotbarCategory = hotbarCategory or activeHotbar()

    local actionType = SafeCall(GetSlotType, slotIndex, hotbarCategory)
    local actionId = SafeCall(GetSlotBoundId, slotIndex, hotbarCategory)
    local isEmpty = actionType == nil
        or (ACTION_TYPE_NOTHING ~= nil and actionType == ACTION_TYPE_NOTHING)
        or not actionId
        or actionId == 0

    local abilityId, craftedAbilityId = nil, nil
    local name, icon, usable = nil, nil, false
    local cooldownRemaining, cooldownDuration = nil, nil
    if not isEmpty then
        if ACTION_TYPE_CRAFTED_ABILITY ~= nil and actionType == ACTION_TYPE_CRAFTED_ABILITY then
            craftedAbilityId = actionId
            abilityId = SafeCall(GetAbilityIdForCraftedAbilityId, actionId)
        elseif actionType == ACTION_TYPE_ABILITY then
            abilityId = actionId
        end
        name = NonEmpty(LAC.FormatName(SafeCall(GetSlotName, slotIndex, hotbarCategory)))
        icon = NonEmpty(SafeCall(GetSlotTexture, slotIndex, hotbarCategory))
        usable = SafeCall(IsSlotUsable, slotIndex, hotbarCategory) == true
        local cdOk, remain, duration = LAC.SafeCallMulti(GetSlotCooldownInfo, slotIndex, hotbarCategory)
        if cdOk then
            cooldownRemaining, cooldownDuration = remain, duration
        end
    end

    return {
        hotbarCategory = hotbarCategory,
        slotIndex = slotIndex,
        actionType = actionType,
        actionId = actionId,
        isEmpty = isEmpty,
        isUltimate = slotIndex == Hotbar.ULTIMATE_SLOT,
        abilityId = abilityId,
        craftedAbilityId = craftedAbilityId,
        name = name,
        icon = icon,
        usable = usable,
        cooldownRemaining = cooldownRemaining,
        cooldownDuration = cooldownDuration,
    }
end

--- Every skill slot of a bar (FIRST_SLOT..ULTIMATE_SLOT). hotbarCategory defaults to the active bar.
--- Returns { list = {records incl. empty}, count = nonEmptyCount, total = slotCount }.
function Hotbar.ComposeBar(hotbarCategory)
    hotbarCategory = hotbarCategory or activeHotbar()
    local list = {}
    local count = 0
    for slotIndex = Hotbar.FIRST_SLOT, Hotbar.ULTIMATE_SLOT do
        local rec = Hotbar.ComposeSlot(slotIndex, hotbarCategory)
        list[#list + 1] = rec
        if not rec.isEmpty then
            count = count + 1
        end
    end
    return { list = list, count = count, total = #list }
end
