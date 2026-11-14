-- LibApiCompose — Quickslot.Compose (style E)

local LAC = LibApiCompose
LAC.Quickslot = LAC.Quickslot or {}
local Quickslot = LAC.Quickslot
local SafeCall = LAC.SafeCall

Quickslot.WHEEL_SIZE = type(ACTION_BAR_UTILITY_BAR_SIZE) == "number" and ACTION_BAR_UTILITY_BAR_SIZE or 8

local function defaultHotbar()
    return HOTBAR_CATEGORY_QUICKSLOT_WHEEL
end

local function nonEmpty(s)
    return type(s) == "string" and s ~= ""
end

--- Compose utility-wheel / hotbar slot → fresh record (always returned; check isEmpty).
--- Identity: hotbarCategory, slotIndex, actionType, actionId
--- Fields: isEmpty, name, texture, icon, count, usable, collectibleCategory
--- slotIndex is 1-based for GetSlotBoundId-style APIs.
function Quickslot.Compose(slotIndex, hotbarCategory, _opts)
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

    local name, texture, count, usable = nil, nil, nil, false
    if not isEmpty then
        name = LAC.FormatName(SafeCall(GetSlotName, slotIndex, hotbarCategory))
        texture = SafeCall(GetSlotTexture, slotIndex, hotbarCategory)
        count = SafeCall(GetSlotItemCount, slotIndex, hotbarCategory)
        usable = SafeCall(IsSlotUsable, slotIndex, hotbarCategory) == true
    end

    local collectibleCategory = nil
    local icon = texture
    if not isEmpty and actionType == ACTION_TYPE_COLLECTIBLE and actionId > 0 then
        local rec = LAC.Collectible.Compose(actionId)
        if rec then
            collectibleCategory = rec.category
            if not nonEmpty(icon) then
                icon = rec.icon
            end
            if not nonEmpty(name) then
                name = rec.name
            end
        end
    end

    return {
        hotbarCategory = hotbarCategory,
        slotIndex = slotIndex,
        actionType = actionType,
        actionId = actionId,
        isEmpty = isEmpty,
        name = name,
        texture = texture,
        icon = icon,
        count = count,
        usable = usable,
        collectibleCategory = collectibleCategory,
    }
end

--- All wheel slots 1..WHEEL_SIZE for a hotbar category (default: quickslot wheel).
--- Returns { list = {records incl. empty}, count = nonEmptyCount, total = WHEEL_SIZE }.
function Quickslot.ComposeWheel(hotbarCategory)
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
