-- LibApiCompose — Core
-- Canonical SafeCall / SafeCallMulti, keys, sentinels, ClearCache.

LibApiCompose = LibApiCompose or {}
local LAC = LibApiCompose

LAC.name = "LibApiCompose"
LAC.VERSION = "@project-version@"
LAC.ADDON_VERSION = 0 -- set at build from encoded semver; runtime may refresh from manifest
LAC.NONE = "LAC_NONE"

-- Action bar: ZOS globals are 0-based; GetSlotBoundId / related slot APIs are 1-based.
LAC.HOTBAR = {
    -- Prefer game globals when present; documented for consumers.
    CATEGORY_PRIMARY = HOTBAR_CATEGORY_PRIMARY,
    CATEGORY_BACKUP = HOTBAR_CATEGORY_BACKUP,
    CATEGORY_QUICKSLOT_WHEEL = HOTBAR_CATEGORY_QUICKSLOT_WHEEL,
}

------------------------------------------------------------
-- Logging (optional LibDebugLogger)
------------------------------------------------------------

local function getLogger()
    if LibDebugLogger and LibDebugLogger.Create then
        if not LAC._logger then
            LAC._logger = LibDebugLogger.Create(LAC.name)
        end
        return LAC._logger
    end
    return nil
end

function LAC.DebugPrint(category, message)
    local logger = getLogger()
    if not logger then
        return
    end
    local text = message
    if type(message) == "function" then
        text = message()
    end
    if logger.Debug then
        logger:Debug(string.format("[%s] %s", tostring(category), tostring(text)))
    end
end

------------------------------------------------------------
-- SafeCall (canonical — match CM/EAP semantics)
------------------------------------------------------------

--- Call func with pcall preserving multiple return values.
--- Returns success, then the function returns (or error message on failure).
--- Preserves nil holes via select("#") + unpack.
function LAC.SafeCallMulti(func, ...)
    if not func or type(func) ~= "function" then
        local errorMsg = string.format("SafeCallMulti: function is nil or not a function (type=%s)", type(func))
        LAC.DebugPrint("SAFECALL", errorMsg)
        return false, errorMsg
    end

    local function capture(ok, ...)
        return ok, select("#", ...), { ... }
    end

    local pcallOk, count, results = capture(pcall(func, ...))
    if not pcallOk then
        local errorMsg = results[1]
        LAC.DebugPrint("SAFECALL", function()
            return string.format("Error in SafeCallMulti: %s", tostring(errorMsg))
        end)
        return false, errorMsg
    end

    return true, unpack(results, 1, count)
end

--- Call func with pcall; return first result or nil on failure.
function LAC.SafeCall(func, ...)
    local success, result = LAC.SafeCallMulti(func, ...)
    if success then
        return result
    end
    return nil
end

------------------------------------------------------------
-- Keys
------------------------------------------------------------

--- Stable numeric key for bag+slot (bagId * 100000 + slotIndex).
function LAC.SlotKey(bagId, slotIndex)
    bagId = tonumber(bagId) or 0
    slotIndex = tonumber(slotIndex) or 0
    return bagId * 100000 + slotIndex
end

--- Stable numeric key for hotbar category + slot.
function LAC.HotbarSlotKey(hotbarCategory, slotIndex)
    hotbarCategory = tonumber(hotbarCategory) or 0
    slotIndex = tonumber(slotIndex) or 0
    return hotbarCategory * 100000 + slotIndex
end

------------------------------------------------------------
-- Cache
------------------------------------------------------------

LAC._cache = LAC._cache or {}

function LAC.ClearCache()
    LAC._cache = {}
    if LAC.Collectible and LAC.Collectible.ClearCache then
        LAC.Collectible.ClearCache()
    end
end

--- Shallow-copy an array list (1-based).
function LAC.CopyList(list)
    if not list then
        return {}
    end
    local out = {}
    for i = 1, #list do
        out[i] = list[i]
    end
    return out
end

--- Shallow-copy a map table.
function LAC.CopyMap(map)
    if not map then
        return {}
    end
    local out = {}
    for k, v in pairs(map) do
        out[k] = v
    end
    return out
end

------------------------------------------------------------
-- Manifest version refresh (optional)
------------------------------------------------------------

function LAC.RefreshVersionsFromManifest()
    if not GetAddOnMetadata then
        return
    end
    local version = LAC.SafeCall(GetAddOnMetadata, LAC.name, "Version")
    if version and version ~= "" and version ~= "@project-version@" then
        LAC.VERSION = version
    end
    local aov = LAC.SafeCall(GetAddOnMetadata, LAC.name, "AddOnVersion")
    local n = tonumber(aov)
    if n then
        LAC.ADDON_VERSION = n
    end
end

-- Attempt refresh when metadata APIs exist (file load may be early).
if GetAddOnMetadata then
    LAC.RefreshVersionsFromManifest()
end
