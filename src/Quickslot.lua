-- LibApiCompose — Quickslot.Compose (style E)

local LAC = LibApiCompose
LAC.Quickslot = LAC.Quickslot or {}
local Quickslot = LAC.Quickslot

local function defaultHotbar()
    return HOTBAR_CATEGORY_QUICKSLOT_WHEEL
end

--- Compose utility-wheel / hotbar slot.
--- Identity: hotbarCategory, slotIndex, actionType, actionId
--- slotIndex is 1-based for GetSlotBoundId-style APIs.
function Quickslot.Compose(slotIndex, hotbarCategory, _opts)
    if slotIndex == nil then
        return nil
    end
    hotbarCategory = hotbarCategory or defaultHotbar()

    local actionType = nil
    local actionId = nil
    local name = nil
    local texture = nil
    local count = nil
    local usable = nil

    if GetSlotType then
        actionType = LAC.SafeCall(GetSlotType, slotIndex, hotbarCategory)
    end
    if GetSlotBoundId then
        actionId = LAC.SafeCall(GetSlotBoundId, slotIndex, hotbarCategory)
    end
    if GetSlotName then
        name = LAC.SafeCall(GetSlotName, slotIndex, hotbarCategory)
    end
    if GetSlotTexture then
        texture = LAC.SafeCall(GetSlotTexture, slotIndex, hotbarCategory)
    end
    if GetSlotItemCount then
        count = LAC.SafeCall(GetSlotItemCount, slotIndex, hotbarCategory)
    end
    if IsSlotUsable then
        usable = LAC.SafeCall(IsSlotUsable, slotIndex, hotbarCategory) == true
    end

    local collectibleCategory = nil
    local icon = texture
    if actionType == ACTION_TYPE_COLLECTIBLE and actionId and actionId > 0 then
        if GetCollectibleCategoryType then
            collectibleCategory = LAC.SafeCall(GetCollectibleCategoryType, actionId)
        end
        if (not icon or icon == "") and GetCollectibleIcon then
            icon = LAC.SafeCall(GetCollectibleIcon, actionId)
        end
        if (not name or name == "") and GetCollectibleName then
            name = LAC.SafeCall(GetCollectibleName, actionId)
        end
    end

    return {
        hotbarCategory = hotbarCategory,
        slotIndex = slotIndex,
        actionType = actionType,
        actionId = actionId,
        name = name,
        texture = texture,
        icon = icon,
        count = count,
        usable = usable,
        collectibleCategory = collectibleCategory,
    }
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
