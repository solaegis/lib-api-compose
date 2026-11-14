-- LibApiCompose — Companion active + roster

local LAC = LibApiCompose
LAC.Companion = LAC.Companion or {}
local Companion = LAC.Companion

--- Active companion snapshot (nil if none).
--- Identity: collectibleId, defId (when available)
function Companion.ComposeActive(_opts)
    local has = false
    if HasActiveCompanion then
        has = LAC.SafeCall(HasActiveCompanion) == true
    end
    if not has then
        return nil
    end

    local defId = nil
    if GetActiveCompanionDefId then
        defId = LAC.SafeCall(GetActiveCompanionDefId)
    end

    local collectibleId = nil
    if defId and GetCompanionCollectibleId then
        collectibleId = LAC.SafeCall(GetCompanionCollectibleId, defId)
    end
    if (not collectibleId or collectibleId <= 0) and GetActiveCollectibleByType and COLLECTIBLE_CATEGORY_TYPE_COMPANION then
        local actor = GAMEPLAY_ACTOR_CATEGORY_PLAYER
        collectibleId = LAC.SafeCall(GetActiveCollectibleByType, COLLECTIBLE_CATEGORY_TYPE_COMPANION, actor)
            or LAC.SafeCall(GetActiveCollectibleByType, COLLECTIBLE_CATEGORY_TYPE_COMPANION)
    end

    local name = nil
    local icon = nil
    if collectibleId and collectibleId > 0 then
        local rec = LAC.Collectible.Compose(collectibleId)
        if rec then
            name = rec.name
            icon = rec.icon
        end
    end

    return {
        defId = defId,
        collectibleId = collectibleId,
        id = collectibleId,
        name = name,
        icon = icon,
        isActive = true,
    }
end

--- Roster of unlocked companions (category walk).
--- Returns { list, count, total }.
function Companion.ComposeRoster()
    if not COLLECTIBLE_CATEGORY_TYPE_COMPANION then
        return { list = {}, count = 0, total = 0 }
    end
    return LAC.Collectible.ComposeUnlockedByCategory(COLLECTIBLE_CATEGORY_TYPE_COMPANION)
end
