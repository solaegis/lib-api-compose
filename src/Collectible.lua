-- LibApiCompose — Collectible compose + category lists (styles C, G)
--
-- Caching model:
--   * Static facts (name, icon, category) are memoised per id.
--   * Volatile facts (unlocked, active, blocked, cooldown, nickname) are read live on every Compose.
--   * Unlocked-by-category id lists are memoised and cleared by the library's own
--     collection events (read-only self-invalidation; no callback bus).
--   * Name indexes are memoised until ClearCache (they do not depend on unlock state).
--   * Every returned record/list/map is freshly built — callers own it.

local LAC = LibApiCompose
LAC.Collectible = LAC.Collectible or {}
local Collectible = LAC.Collectible
local SafeCall = LAC.SafeCall

local _static = {}
local _unlockedIds = {}
local _nameIndex = {}

--- Drop every collectible memo (static facts, category lists, name indexes).
function Collectible.ClearCache()
    _static = {}
    _unlockedIds = {}
    _nameIndex = {}
end

--- Drop the unlocked-by-category lists. Called by the library's own collection events.
--- Name indexes cover every collectible regardless of unlock state, so they are kept.
function Collectible.InvalidateLists()
    _unlockedIds = {}
end

-- Static facts for an id, or nil when the id is not a real collectible (never memoised then).
local function staticFacts(collectibleId, skipCache)
    if not skipCache and _static[collectibleId] then
        return _static[collectibleId]
    end

    local name = SafeCall(GetCollectibleName, collectibleId)
    if (name == nil or name == "") and GetCollectibleInfo then
        local ok, infoName = LAC.SafeCallMulti(GetCollectibleInfo, collectibleId)
        if ok then
            name = infoName
        end
    end
    name = LAC.NonEmpty(LAC.FormatName(name))
    local category = SafeCall(GetCollectibleCategoryType, collectibleId)
    if name == nil and (category == nil or category == (COLLECTIBLE_CATEGORY_TYPE_INVALID or 0)) then
        return nil
    end

    local facts = {
        name = name,
        icon = LAC.NonEmpty(SafeCall(GetCollectibleIcon, collectibleId)),
        category = category,
    }
    if not skipCache then
        _static[collectibleId] = facts
    end
    return facts
end

local function playerActor()
    return GAMEPLAY_ACTOR_CATEGORY_PLAYER
end

--- Compose collectible id → fresh record, or nil when the id is not a collectible.
--- Identity: id
--- Fields: name, nickname, icon, category, unlocked, unlockState, active, isBlocked,
---         cooldownRemaining (ms), cooldownDuration (ms), description?, link?
--- opts.skipCache — bypass the static-facts memo.
--- opts.includeDescription — also fetch the description text.
--- opts.includeLink — also build the collectible link.
function Collectible.Compose(collectibleId, opts)
    opts = opts or {}
    collectibleId = tonumber(collectibleId)
    if not collectibleId or collectibleId <= 0 then
        return nil
    end

    local facts = staticFacts(collectibleId, opts.skipCache)
    if not facts then
        return nil
    end

    local cdOk, cooldownRemaining, cooldownDuration =
        LAC.SafeCallMulti(GetCollectibleCooldownAndDuration, collectibleId)
    if not cdOk then
        cooldownRemaining, cooldownDuration = nil, nil
    end

    local description, link = nil, nil
    if opts.includeDescription then
        description = LAC.NonEmpty(SafeCall(GetCollectibleDescription, collectibleId))
    end
    if opts.includeLink then
        link = LAC.NonEmpty(SafeCall(GetCollectibleLink, collectibleId, LINK_STYLE_DEFAULT or 0))
    end

    return {
        id = collectibleId,
        name = facts.name,
        nickname = LAC.NonEmpty(LAC.FormatName(SafeCall(GetCollectibleNickname, collectibleId))),
        icon = facts.icon,
        category = facts.category,
        unlocked = SafeCall(IsCollectibleUnlocked, collectibleId) == true,
        unlockState = SafeCall(GetCollectibleUnlockStateById, collectibleId),
        active = SafeCall(IsCollectibleActive, collectibleId, playerActor()) == true,
        isBlocked = SafeCall(IsCollectibleBlocked, collectibleId, playerActor()) == true,
        cooldownRemaining = cooldownRemaining,
        cooldownDuration = cooldownDuration,
        description = description,
        link = link,
    }
end

local function unlockedIdsFor(categoryType)
    local cached = _unlockedIds[categoryType]
    if cached then
        return cached
    end
    local total = SafeCall(GetTotalCollectiblesByCategoryType, categoryType) or 0
    local ids = {}
    for i = 1, total do
        local id = SafeCall(GetCollectibleIdFromType, categoryType, i)
        if id and id > 0 and SafeCall(IsCollectibleUnlocked, id) == true then
            ids[#ids + 1] = id
        end
    end
    cached = { ids = ids, total = total }
    _unlockedIds[categoryType] = cached
    return cached
end

--- Unlocked collectibles for a category type.
--- Returns { list = {fresh records...}, count = n, total = m }.
function Collectible.ComposeUnlockedByCategory(categoryType)
    if categoryType == nil then
        return { list = {}, count = 0, total = 0 }
    end

    local cached = unlockedIdsFor(categoryType)
    local list = {}
    for i = 1, #cached.ids do
        local rec = Collectible.Compose(cached.ids[i])
        if rec then
            list[#list + 1] = rec
        end
    end
    return { list = list, count = #list, total = cached.total }
end

-- Shared (cached) lowercased-name → id map for a category. Never returned to callers directly.
local function nameIndexFor(categoryType)
    local map = _nameIndex[categoryType]
    if map then
        return map
    end
    map = {}
    local total = SafeCall(GetTotalCollectiblesByCategoryType, categoryType) or 0
    for i = 1, total do
        local id = SafeCall(GetCollectibleIdFromType, categoryType, i)
        local facts = id and id > 0 and staticFacts(id) or nil
        if facts and facts.name then
            local key = LAC.LowerName(facts.name)
            if map[key] == nil then
                map[key] = id
            end
        end
    end
    _nameIndex[categoryType] = map
    return map
end

--- Lowercased name → id index for a category (all collectibles, not just unlocked).
--- On duplicate names the first (lowest index) id wins. Returns a fresh map (a full copy —
--- for single lookups use FindByName).
function Collectible.IndexByName(categoryType)
    if categoryType == nil then
        return {}
    end
    return LAC.CopyMap(nameIndexFor(categoryType))
end

--- Collectible id for a (case-insensitive, formatted) name in a category, or nil. O(1) after
--- the first call per category.
function Collectible.FindByName(categoryType, name)
    if categoryType == nil or type(name) ~= "string" or name == "" then
        return nil
    end
    return nameIndexFor(categoryType)[LAC.LowerName(LAC.FormatName(name))]
end

------------------------------------------------------------
-- Self-invalidation (read-only; ADR-008)
------------------------------------------------------------

local INVALIDATING_EVENTS = {
    "EVENT_COLLECTION_UPDATED",
    "EVENT_COLLECTIBLES_UNLOCK_STATE_CHANGED",
    "EVENT_COLLECTIBLE_UPDATED",
}

if EVENT_MANAGER and EVENT_MANAGER.RegisterForEvent then
    local namespace = LAC.name .. "_Collectible"
    for _, eventName in ipairs(INVALIDATING_EVENTS) do
        local eventCode = _G[eventName]
        if eventCode ~= nil then
            EVENT_MANAGER:RegisterForEvent(namespace, eventCode, Collectible.InvalidateLists)
        end
    end
end
