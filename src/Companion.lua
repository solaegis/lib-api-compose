-- LibApiCompose — Companion active + roster

local LAC = LibApiCompose
LAC.Companion = LAC.Companion or {}
local Companion = LAC.Companion
local SafeCall = LAC.SafeCall

local function compose(defId, isActive)
    local collectibleId = nil
    if defId and defId > 0 then
        collectibleId = SafeCall(GetCompanionCollectibleId, defId)
    end
    if isActive and (not collectibleId or collectibleId <= 0) and COLLECTIBLE_CATEGORY_TYPE_COMPANION then
        collectibleId =
            SafeCall(GetActiveCollectibleByType, COLLECTIBLE_CATEGORY_TYPE_COMPANION, GAMEPLAY_ACTOR_CATEGORY_PLAYER)
    end
    if collectibleId and collectibleId <= 0 then
        collectibleId = nil
    end

    local name, icon = nil, nil
    if collectibleId then
        local rec = LAC.Collectible.Compose(collectibleId)
        if rec then
            name, icon = rec.name, rec.icon
        end
    end
    if not name and defId and defId > 0 then
        name = LAC.NonEmpty(LAC.FormatName(SafeCall(GetCompanionName, defId)))
    end

    return {
        defId = defId,
        collectibleId = collectibleId,
        id = collectibleId,
        name = name,
        icon = icon,
        isActive = isActive,
        isPending = not isActive,
    }
end

--- Active companion snapshot → fresh record (nil if none).
--- Identity: collectibleId (alias id), defId (when available)
--- Fields: name, icon, isActive, isPending, level, xp, rapport, rapportLevel
--- opts.includePending — when no companion is active but one is being summoned, return its
--- record with isActive = false, isPending = true (no level / rapport fields).
function Companion.ComposeActive(opts)
    if SafeCall(HasActiveCompanion) == true then
        local rec = compose(SafeCall(GetActiveCompanionDefId), true)
        local ok, level, xp = LAC.SafeCallMulti(GetActiveCompanionLevelInfo)
        if ok then
            rec.level, rec.xp = level, xp
        end
        rec.rapport = SafeCall(GetActiveCompanionRapport)
        rec.rapportLevel = SafeCall(GetActiveCompanionRapportLevel)
        return rec
    end
    if opts and opts.includePending and SafeCall(HasPendingCompanion) == true then
        return compose(SafeCall(GetPendingCompanionDefId), false)
    end
    return nil
end

--- Roster of unlocked companions (category walk).
--- Returns { list, count, total } of Collectible records.
function Companion.ComposeRoster()
    if not COLLECTIBLE_CATEGORY_TYPE_COMPANION then
        return { list = {}, count = 0, total = 0 }
    end
    return LAC.Collectible.ComposeUnlockedByCategory(COLLECTIBLE_CATEGORY_TYPE_COMPANION)
end
