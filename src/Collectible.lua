-- LibApiCompose — Collectible compose + category lists (styles C, G)

local LAC = LibApiCompose
LAC.Collectible = LAC.Collectible or {}
local Collectible = LAC.Collectible

local _byId = {}
local _byCategory = {}
local _nameIndex = {}

local function cleanName(name)
    if not name or type(name) ~= "string" then
        return name
    end
    return name:gsub("%^%w+$", "")
end

function Collectible.ClearCache()
    _byId = {}
    _byCategory = {}
    _nameIndex = {}
end

--- Compose collectible id → record, or nil if invalid.
--- Identity: id
--- Fields: name, nickname, icon, category, unlocked, active
function Collectible.Compose(collectibleId, opts)
    opts = opts or {}
    collectibleId = tonumber(collectibleId)
    if not collectibleId or collectibleId <= 0 then
        return nil
    end

    if not opts.skipCache and _byId[collectibleId] then
        -- Return a shallow copy of the cached record (ownership)
        local cached = _byId[collectibleId]
        local copy = {}
        for k, v in pairs(cached) do
            copy[k] = v
        end
        return copy
    end

    local name = cleanName(LAC.SafeCall(GetCollectibleName, collectibleId))
    if not name and GetCollectibleInfo then
        local ok, infoName = LAC.SafeCallMulti(GetCollectibleInfo, collectibleId)
        if ok then
            name = cleanName(infoName)
        end
    end

    local nickname = nil
    if GetCollectibleNickname then
        nickname = cleanName(LAC.SafeCall(GetCollectibleNickname, collectibleId))
    end

    local icon = nil
    if GetCollectibleIcon then
        icon = LAC.SafeCall(GetCollectibleIcon, collectibleId)
    end

    local category = nil
    if GetCollectibleCategoryType then
        category = LAC.SafeCall(GetCollectibleCategoryType, collectibleId)
    end

    local unlocked = false
    if IsCollectibleUnlocked then
        unlocked = LAC.SafeCall(IsCollectibleUnlocked, collectibleId) == true
    end

    local active = false
    if IsCollectibleActive then
        local actor = GAMEPLAY_ACTOR_CATEGORY_PLAYER
        active = LAC.SafeCall(IsCollectibleActive, collectibleId, actor) == true
            or LAC.SafeCall(IsCollectibleActive, collectibleId) == true
    end

    local rec = {
        id = collectibleId,
        name = name,
        nickname = nickname,
        icon = icon,
        category = category,
        unlocked = unlocked,
        active = active,
    }

    if not opts.skipCache then
        _byId[collectibleId] = rec
    end

    local copy = {}
    for k, v in pairs(rec) do
        copy[k] = v
    end
    return copy
end

--- Unlocked collectibles for a category type.
--- Returns { list = {...}, count = n, total = m } (list is a copy).
function Collectible.ComposeUnlockedByCategory(categoryType)
    if categoryType == nil then
        return { list = {}, count = 0, total = 0 }
    end

    if _byCategory[categoryType] then
        local cached = _byCategory[categoryType]
        return {
            list = LAC.CopyList(cached.list),
            count = cached.count,
            total = cached.total,
        }
    end

    local total = 0
    if GetTotalCollectiblesByCategoryType then
        total = LAC.SafeCall(GetTotalCollectiblesByCategoryType, categoryType) or 0
    end

    local list = {}
    for i = 1, total do
        local id = LAC.SafeCall(GetCollectibleIdFromType, categoryType, i)
        if id then
            local unlocked = LAC.SafeCall(IsCollectibleUnlocked, id)
            if unlocked then
                local rec = Collectible.Compose(id)
                if rec then
                    list[#list + 1] = rec
                end
            end
        end
    end

    local packed = { list = list, count = #list, total = total }
    _byCategory[categoryType] = packed
    return {
        list = LAC.CopyList(list),
        count = packed.count,
        total = packed.total,
    }
end

--- Name → id index for a category (lowercased names). Returns a copy of the map.
function Collectible.IndexByName(categoryType)
    if categoryType == nil then
        return {}
    end
    if _nameIndex[categoryType] then
        return LAC.CopyMap(_nameIndex[categoryType])
    end

    local map = {}
    local total = LAC.SafeCall(GetTotalCollectiblesByCategoryType, categoryType) or 0
    for i = 1, total do
        local id = LAC.SafeCall(GetCollectibleIdFromType, categoryType, i)
        if id then
            local name = cleanName(LAC.SafeCall(GetCollectibleName, id))
            if name and name ~= "" then
                map[string.lower(name)] = id
            end
        end
    end
    _nameIndex[categoryType] = map
    return LAC.CopyMap(map)
end
