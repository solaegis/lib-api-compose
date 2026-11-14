-- LibApiCompose — Collectible compose + category lists (styles C, G)
--
-- Caching model:
--   * Static facts (name, icon, category) are memoised per id.
--   * Volatile facts (unlocked, active, nickname) are read live on every Compose.
--   * Unlocked-by-category id lists and name indexes are memoised and cleared by the
--     library's own collection events (read-only self-invalidation; no callback bus).
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

--- Drop only membership caches (unlocked lists + name indexes). Called by collection events.
function Collectible.InvalidateLists()
    _unlockedIds = {}
    _nameIndex = {}
end

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

    local facts = {
        name = LAC.FormatName(name),
        icon = SafeCall(GetCollectibleIcon, collectibleId),
        category = SafeCall(GetCollectibleCategoryType, collectibleId),
    }
    if not skipCache then
        _static[collectibleId] = facts
    end
    return facts
end

local function isActive(collectibleId)
    if GAMEPLAY_ACTOR_CATEGORY_PLAYER ~= nil then
        return SafeCall(IsCollectibleActive, collectibleId, GAMEPLAY_ACTOR_CATEGORY_PLAYER) == true
    end
    return SafeCall(IsCollectibleActive, collectibleId) == true
end

--- Compose collectible id → fresh record, or nil if invalid.
--- Identity: id
--- Fields: name, nickname, icon, category, unlocked, active
--- opts.skipCache — bypass the static-facts memo.
function Collectible.Compose(collectibleId, opts)
    opts = opts or {}
    collectibleId = tonumber(collectibleId)
    if not collectibleId or collectibleId <= 0 then
        return nil
    end

    local facts = staticFacts(collectibleId, opts.skipCache)
    local nickname = LAC.FormatName(SafeCall(GetCollectibleNickname, collectibleId))
    if nickname == "" then
        nickname = nil
    end

    return {
        id = collectibleId,
        name = facts.name,
        nickname = nickname,
        icon = facts.icon,
        category = facts.category,
        unlocked = SafeCall(IsCollectibleUnlocked, collectibleId) == true,
        active = isActive(collectibleId),
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
        if id and SafeCall(IsCollectibleUnlocked, id) == true then
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

--- Lowercased name → id index for a category (all collectibles, not just unlocked).
--- On duplicate names the first (lowest index) id wins. Returns a fresh map.
function Collectible.IndexByName(categoryType)
    if categoryType == nil then
        return {}
    end
    if _nameIndex[categoryType] then
        return LAC.CopyMap(_nameIndex[categoryType])
    end

    local map = {}
    local total = SafeCall(GetTotalCollectiblesByCategoryType, categoryType) or 0
    for i = 1, total do
        local id = SafeCall(GetCollectibleIdFromType, categoryType, i)
        if id then
            local name = staticFacts(id).name
            if name and name ~= "" then
                local key = LAC.LowerName(name)
                if map[key] == nil then
                    map[key] = id
                end
            end
        end
    end
    _nameIndex[categoryType] = map
    return LAC.CopyMap(map)
end

------------------------------------------------------------
-- Self-invalidation (read-only; ADR-008)
------------------------------------------------------------

local INVALIDATING_EVENTS = {
    "EVENT_COLLECTION_UPDATED",
    "EVENT_COLLECTIBLES_UNLOCK_STATE_CHANGED",
    "EVENT_COLLECTIBLE_UPDATED",
    "EVENT_COLLECTIBLES_UPDATED",
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
