-- LibApiCompose — Core
-- Canonical SafeCall / SafeCallMulti, keys, sentinels, name helpers, ClearCache.

LibApiCompose = LibApiCompose or {}
local LAC = LibApiCompose

LAC.name = "LibApiCompose"
LAC.VERSION = "@project-version@"
LAC.ADDON_VERSION = 10000 -- stamped at build from the git tag (scripts/set-addon-version.sh)
LAC.NONE = "LAC_NONE" -- explicit "none" sentinel for consumer lists (ADR-009)

-- Internal helpers shared between modules. Not part of the public contract.
LAC._internal = LAC._internal or {}

-- Action bar: hotbar categories are game enums; slot indices for
-- GetSlotBoundId / GetSlotType on the quickslot wheel are 1-based.
LAC.HOTBAR = {
    CATEGORY_PRIMARY = HOTBAR_CATEGORY_PRIMARY,
    CATEGORY_BACKUP = HOTBAR_CATEGORY_BACKUP,
    CATEGORY_QUICKSLOT_WHEEL = HOTBAR_CATEGORY_QUICKSLOT_WHEEL,
}

------------------------------------------------------------
-- Version
------------------------------------------------------------

--- True when the loaded library's encoded AddOnVersion is >= n.
--- Use for feature detection: if LibApiCompose.AtLeast(10100) then ... end
function LAC.AtLeast(n)
    return (tonumber(LAC.ADDON_VERSION) or 0) >= (tonumber(n) or 0)
end

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
    if not logger or not logger.Debug then
        return
    end
    local text = message
    if type(message) == "function" then
        text = message()
    end
    logger:Debug(string.format("[%s] %s", tostring(category), tostring(text)))
end

------------------------------------------------------------
-- SafeCall (canonical — match CM/EAP semantics)
------------------------------------------------------------

local traceback = debug and debug.traceback

local function capture(ok, ...)
    return ok, select("#", ...), { ... }
end

--- Call func with pcall preserving multiple return values.
--- Returns success, then the function returns (or the error message on failure).
--- Preserves nil holes via select("#") + unpack.
--- A nil / non-function func soft-fails silently (missing ZOS symbol on this client).
--- When LibDebugLogger is present, errors are logged with a traceback.
function LAC.SafeCallMulti(func, ...)
    if type(func) ~= "function" then
        return false, "SafeCallMulti: function is nil or not a function (type=" .. type(func) .. ")"
    end

    local logger = getLogger()
    local pcallOk, count, results
    if logger and traceback then
        local nArgs, args = select("#", ...), { ... }
        local trace
        pcallOk, count, results = capture(xpcall(function()
            return func(unpack(args, 1, nArgs))
        end, function(err)
            trace = traceback(tostring(err), 2)
            return err
        end))
        if not pcallOk then
            LAC.DebugPrint("SAFECALL", trace or tostring(results[1]))
        end
    else
        pcallOk, count, results = capture(pcall(func, ...))
    end

    if not pcallOk then
        return false, results[1]
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

-- 2^24: larger than any slot index, including BAG_VIRTUAL (slotIndex == itemId),
-- and products stay exact integers in Lua doubles.
LAC.KEY_STRIDE = 16777216

--- Stable numeric key for bag+slot (bagId * KEY_STRIDE + slotIndex).
function LAC.SlotKey(bagId, slotIndex)
    bagId = tonumber(bagId) or 0
    slotIndex = tonumber(slotIndex) or 0
    return bagId * LAC.KEY_STRIDE + slotIndex
end

--- Stable numeric key for hotbar category + slot.
function LAC.HotbarSlotKey(hotbarCategory, slotIndex)
    hotbarCategory = tonumber(hotbarCategory) or 0
    slotIndex = tonumber(slotIndex) or 0
    return hotbarCategory * LAC.KEY_STRIDE + slotIndex
end

------------------------------------------------------------
-- Names
------------------------------------------------------------

--- Strip ZOS grammar suffixes (e.g. "Bear^n", "Mirri Elendis^F") for display.
--- Uses zo_strformat when available; falls back to a pattern strip.
function LAC.FormatName(name)
    if type(name) ~= "string" or name == "" then
        return name
    end
    if zo_strformat then
        local formatted = LAC.SafeCall(zo_strformat, "<<1>>", name)
        if type(formatted) == "string" then
            return formatted
        end
    end
    return (name:gsub("%^[%w:]+$", ""))
end

--- Locale-aware lowercase (zo_strlower handles UTF-8 on DE/FR clients).
function LAC.LowerName(name)
    if type(name) ~= "string" then
        return name
    end
    if zo_strlower then
        local lowered = LAC.SafeCall(zo_strlower, name)
        if type(lowered) == "string" then
            return lowered
        end
    end
    return string.lower(name)
end

------------------------------------------------------------
-- Cache
------------------------------------------------------------

--- Clear every memo cache owned by the library.
function LAC.ClearCache()
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
