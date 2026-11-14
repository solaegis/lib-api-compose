-- LibApiCompose — Companion active + roster

local LAC = LibApiCompose
LAC.Companion = LAC.Companion or {}
local Companion = LAC.Companion

--- Active companion snapshot → fresh record (nil if none).
--- Identity: collectibleId (alias id), defId (when available)
--- Fields: name, icon, isActive
function Companion.ComposeActive(_opts)
    if LAC.SafeCall(HasActiveCompanion) ~= true then
        return nil
    end

    local defId = LAC.SafeCall(GetActiveCompanionDefId)

    local collectibleId = nil
    if defId then
        collectibleId = LAC.SafeCall(GetCompanionCollectibleId, defId)
    end
    if (not collectibleId or collectibleId <= 0) and COLLECTIBLE_CATEGORY_TYPE_COMPANION then
        collectibleId = LAC.SafeCall(
            GetActiveCollectibleByType,
            COLLECTIBLE_CATEGORY_TYPE_COMPANION,
            GAMEPLAY_ACTOR_CATEGORY_PLAYER
        )
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
