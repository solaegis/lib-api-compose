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

-- Action bar: hotbar categories are game enums. Wheel slots are 1-based (1..Quickslot.WHEEL_SIZE);
-- skill bar slots run ACTION_BAR_FIRST_NORMAL_SLOT_INDEX + 1 .. ACTION_BAR_ULTIMATE_SLOT_INDEX + 1.
LAC.HOTBAR = {
    CATEGORY_PRIMARY = HOTBAR_CATEGORY_PRIMARY,
    CATEGORY_BACKUP = HOTBAR_CATEGORY_BACKUP,
    CATEGORY_QUICKSLOT_WHEEL = HOTBAR_CATEGORY_QUICKSLOT_WHEEL,
    CATEGORY_ALLY_WHEEL = HOTBAR_CATEGORY_ALLY_WHEEL,
    CATEGORY_EMOTE_WHEEL = HOTBAR_CATEGORY_EMOTE_WHEEL,
    CATEGORY_MEMENTO_WHEEL = HOTBAR_CATEGORY_MEMENTO_WHEEL,
    CATEGORY_TOOL_WHEEL = HOTBAR_CATEGORY_TOOL_WHEEL,
}

------------------------------------------------------------
-- Version
------------------------------------------------------------

--- True when the loaded library's encoded AddOnVersion is >= n.
--- Use for feature detection: if LibApiCompose.AtLeast(10100) then ... end
function LAC.AtLeast(n)
    return (tonumber(LAC.ADDON_VERSION) or 0) >= (tonumber(n) or 0)
end

--- Check that every ZOS function and constant the library reads exists on this client.
--- Returns { ok = n, total = n, missing = { "Name", ... } }. In game:
---   /script d(LibApiCompose.SelfTest())
--- A non-empty `missing` after a game patch means ZOS renamed or removed something; the
--- affected record fields soft-fail to nil until the library is updated.
function LAC.SelfTest()
    local symbols = LAC._internal.ZOS_SYMBOLS or {}
    local missing = {}
    for i = 1, #symbols do
        if _G[symbols[i]] == nil then
            missing[#missing + 1] = symbols[i]
        end
    end
    return { ok = #symbols - #missing, total = #symbols, missing = missing }
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

local function resolve(message)
    if type(message) == "function" then
        return message()
    end
    return message
end

--- Write "[category] message" to LibDebugLogger at debug level (no-op without the logger).
--- message may be a function returning the text; it is only called when a logger exists.
function LAC.DebugPrint(category, message)
    local logger = getLogger()
    if not logger or not logger.Debug then
        return
    end
    logger:Debug(string.format("[%s] %s", tostring(category), tostring(resolve(message))))
end

-- Failures are logged once per distinct message so a per-frame failure cannot flood the log.
local MAX_REPORTED = 200
local _reported = {}
local _reportedCount = 0

local function reportOnce(category, key, message)
    local logger = getLogger()
    if not logger then
        return
    end
    key = tostring(key)
    if _reported[key] then
        return
    end
    if _reportedCount >= MAX_REPORTED then
        return
    end
    _reported[key] = true
    _reportedCount = _reportedCount + 1
    local text = string.format("[%s] %s", tostring(category), tostring(resolve(message)))
    if logger.Warn then
        logger:Warn(text)
    elseif logger.Debug then
        logger:Debug(text)
    end
end

LAC._internal.reportOnce = reportOnce

local _debug = false

--- Enable/disable debug mode. When enabled (and LibDebugLogger is installed) SafeCall failures
--- are logged with a full traceback, at the cost of extra allocations per call.
function LAC.SetDebug(enabled)
    _debug = enabled == true
end

--- True when debug mode is enabled.
function LAC.IsDebug()
    return _debug
end

------------------------------------------------------------
-- SafeCall (canonical — match CM/EAP semantics)
------------------------------------------------------------

local traceback = debug and debug.traceback

-- Tail of the fast path: forwards every return value without building a table.
local function finish(ok, ...)
    if ok then
        return true, ...
    end
    local err = ...
    reportOnce("SAFECALL", err, err)
    return false, err
end

local function capture(ok, ...)
    return ok, select("#", ...), { ... }
end

--- Call func with pcall preserving multiple return values (nil holes included).
--- Returns true plus the function's returns, or false plus the error value.
--- A nil / non-function func soft-fails (missing ZOS symbol on this client).
--- With LibDebugLogger installed each distinct failure is logged once; LAC.SetDebug(true)
--- adds tracebacks.
function LAC.SafeCallMulti(func, ...)
    if type(func) ~= "function" then
        local message = "SafeCallMulti: function is nil or not a function (type=" .. type(func) .. ")"
        if _debug and traceback then
            reportOnce("SAFECALL", traceback(message, 2), function()
                return traceback(message, 3)
            end)
        else
            reportOnce("SAFECALL", message, message .. " — LAC.SetDebug(true) for a traceback")
        end
        return false, message
    end

    if not (_debug and traceback and getLogger()) then
        return finish(pcall(func, ...))
    end

    -- Debug path: xpcall takes no arguments in Lua 5.1, hence the closure.
    local nArgs, args = select("#", ...), { ... }
    local trace
    local pcallOk, count, results = capture(xpcall(function()
        return func(unpack(args, 1, nArgs))
    end, function(err)
        trace = traceback(tostring(err), 2)
        return err
    end))
    if not pcallOk then
        reportOnce("SAFECALL", trace or results[1], trace or results[1])
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
--- Also resets the logged-failure dedupe, so failures are reported again.
function LAC.ClearCache()
    _reported = {}
    _reportedCount = 0
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

--- Empty strings become nil (ZOS getters return "" for "no value").
function LAC.NonEmpty(s)
    if type(s) == "string" and s ~= "" then
        return s
    end
    return nil
end
