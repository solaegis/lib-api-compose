-- LibApiCompose — Quickslot.Compose (style E): the utility wheels
--
-- Wheels (quickslot, ally, emote, memento, tool) use slots 1..WHEEL_SIZE. Skill bars use a
-- different slot range — see Hotbar.lua.

local LAC = LibApiCompose
LAC.Quickslot = LAC.Quickslot or {}
local Quickslot = LAC.Quickslot
local SafeCall = LAC.SafeCall
local NonEmpty = LAC.NonEmpty

Quickslot.WHEEL_SIZE = type(ACTION_BAR_UTILITY_BAR_SIZE) == "number" and ACTION_BAR_UTILITY_BAR_SIZE or 8

local function defaultHotbar()
    return HOTBAR_CATEGORY_QUICKSLOT_WHEEL
end

--- True when hotbarCategory is one of the utility wheels.
function Quickslot.IsWheel(hotbarCategory)
    if hotbarCategory == nil then
        return false
    end
    return hotbarCategory == HOTBAR_CATEGORY_QUICKSLOT_WHEEL
        or hotbarCategory == HOTBAR_CATEGORY_ALLY_WHEEL
        or hotbarCategory == HOTBAR_CATEGORY_EMOTE_WHEEL
        or hotbarCategory == HOTBAR_CATEGORY_MEMENTO_WHEEL
        or hotbarCategory == HOTBAR_CATEGORY_TOOL_WHEEL
end

--- Compose a utility-wheel slot → fresh record (always returned; check isEmpty).
--- Identity: hotbarCategory, slotIndex, actionType, actionId
--- Fields: isEmpty, isCurrent, name, texture, icon, count, usable, itemLink,
---         cooldownRemaining (ms), cooldownDuration (ms), collectibleCategory
--- slotIndex is 1-based. hotbarCategory defaults to the quickslot wheel.
function Quickslot.Compose(slotIndex, hotbarCategory)
    if slotIndex == nil then
        return nil
    end
    hotbarCategory = hotbarCategory or defaultHotbar()

    local actionType = SafeCall(GetSlotType, slotIndex, hotbarCategory)
    local actionId = SafeCall(GetSlotBoundId, slotIndex, hotbarCategory)
    local isEmpty = actionType == nil
        or (ACTION_TYPE_NOTHING ~= nil and actionType == ACTION_TYPE_NOTHING)
        or not actionId
        or actionId == 0

    local name, texture, count, usable, itemLink = nil, nil, nil, false, nil
    local cooldownRemaining, cooldownDuration = nil, nil
    if not isEmpty then
        name = NonEmpty(LAC.FormatName(SafeCall(GetSlotName, slotIndex, hotbarCategory)))
        texture = NonEmpty(SafeCall(GetSlotTexture, slotIndex, hotbarCategory))
        count = SafeCall(GetSlotItemCount, slotIndex, hotbarCategory)
        usable = SafeCall(IsSlotUsable, slotIndex, hotbarCategory) == true
        local cdOk, remain, duration = LAC.SafeCallMulti(GetSlotCooldownInfo, slotIndex, hotbarCategory)
        if cdOk then
            cooldownRemaining, cooldownDuration = remain, duration
        end
        if actionType == ACTION_TYPE_ITEM then
            itemLink = NonEmpty(SafeCall(GetSlotItemLink, slotIndex, hotbarCategory))
        end
    end

    local collectibleCategory = nil
    local icon = texture
    if not isEmpty and actionType == ACTION_TYPE_COLLECTIBLE then
        local rec = LAC.Collectible.Compose(actionId)
        if rec then
            collectibleCategory = rec.category
            icon = icon or rec.icon
            name = name or rec.name
        end
    end

    local isCurrent = false
    if hotbarCategory == defaultHotbar() then
        isCurrent = SafeCall(GetCurrentQuickslot) == slotIndex
    end

    return {
        hotbarCategory = hotbarCategory,
        slotIndex = slotIndex,
        actionType = actionType,
        actionId = actionId,
        isEmpty = isEmpty,
        isCurrent = isCurrent,
        name = name,
        texture = texture,
        icon = icon,
        count = count,
        usable = usable,
        itemLink = itemLink,
        cooldownRemaining = cooldownRemaining,
        cooldownDuration = cooldownDuration,
        collectibleCategory = collectibleCategory,
    }
end

--- All slots 1..WHEEL_SIZE of a utility wheel (default: quickslot wheel).
--- Returns { list = {records incl. empty}, count = nonEmptyCount, total = WHEEL_SIZE }.
--- A non-wheel category (e.g. a skill bar — use Hotbar.ComposeBar) returns an empty result.
function Quickslot.ComposeWheel(hotbarCategory)
    hotbarCategory = hotbarCategory or defaultHotbar()
    if not Quickslot.IsWheel(hotbarCategory) then
        return { list = {}, count = 0, total = 0 }
    end
    local list = {}
    local count = 0
    for slotIndex = 1, Quickslot.WHEEL_SIZE do
        local rec = Quickslot.Compose(slotIndex, hotbarCategory)
        list[#list + 1] = rec
        if rec and not rec.isEmpty then
            count = count + 1
        end
    end
    return { list = list, count = count, total = Quickslot.WHEEL_SIZE }
end

--- Convenience: slotIndex, hotbarCategory from a compose record.
function Quickslot.Args(rec)
    if not rec then
        return nil, nil
    end
    return rec.slotIndex, rec.hotbarCategory
end

--- Convenience: actionType, actionId for SelectSlotSimpleAction-style calls.
function Quickslot.ActionArgs(rec)
    if not rec then
        return nil, nil
    end
    return rec.actionType, rec.actionId
end
