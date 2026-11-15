describe("SafeCall", function()
    it("returns first value on success", function()
        local LAC = LibApiCompose
        local function one()
            return 42
        end
        assertEqual(LAC.SafeCall(one), 42)
    end)

    it("returns nil on error", function()
        local LAC = LibApiCompose
        local function boom()
            error("nope")
        end
        assertEqual(LAC.SafeCall(boom), nil)
    end)

    it("SafeCallMulti preserves multiple returns and success", function()
        local LAC = LibApiCompose
        local function multi()
            return "a", nil, "c"
        end
        local ok, a, b, c = LAC.SafeCallMulti(multi)
        assertEqual(ok, true)
        assertEqual(a, "a")
        assertEqual(b, nil)
        assertEqual(c, "c")
    end)

    it("SafeCallMulti returns false on nil function", function()
        local LAC = LibApiCompose
        local ok = LAC.SafeCallMulti(nil)
        assertEqual(ok, false)
    end)

    it("SafeCallMulti returns the error message on failure", function()
        local LAC = LibApiCompose
        local ok, err = LAC.SafeCallMulti(function()
            error("kaboom", 0)
        end)
        assertEqual(ok, false)
        assertEqual(err, "kaboom")
    end)

    -- Installs a fake LibDebugLogger for the duration of fn; returns the captured messages.
    local function withLogger(fn, methods)
        local LAC = LibApiCompose
        local logged = { warn = {}, debug = {} }
        local logger = {}
        if not methods or methods.Warn then
            logger.Warn = function(_, msg)
                logged.warn[#logged.warn + 1] = msg
            end
        end
        logger.Debug = function(_, msg)
            logged.debug[#logged.debug + 1] = msg
        end
        _G.LibDebugLogger = {
            Create = function()
                return logger
            end,
        }
        LAC._logger = nil
        LAC.ClearCache()
        local ok, err = pcall(fn)
        _G.LibDebugLogger = nil
        LAC._logger = nil
        LAC.SetDebug(false)
        LAC.ClearCache()
        if not ok then
            error(err, 0)
        end
        return logged
    end

    it("logs each distinct failure once, at warn level", function()
        local LAC = LibApiCompose
        local logged = withLogger(function()
            for _ = 1, 5 do
                LAC.SafeCall(function()
                    error("same", 0)
                end)
            end
            LAC.SafeCall(function()
                error("other", 0)
            end)
        end)
        assertEqual(#logged.warn, 2)
        assertTruthy(logged.warn[1]:find("same", 1, true))
        assertFalsy(logged.warn[1]:find("traceback", 1, true), "no traceback unless debug is on")
    end)

    it("falls back to Debug when the logger has no Warn", function()
        local LAC = LibApiCompose
        local logged = withLogger(function()
            LAC.SafeCall(function()
                error("x", 0)
            end)
        end, { Warn = false })
        assertEqual(#logged.debug, 1)
    end)

    it("logs a nil function instead of failing silently", function()
        local LAC = LibApiCompose
        local logged = withLogger(function()
            LAC.SafeCall(nil, 1, 2)
            LAC.SafeCall(nil)
        end)
        assertEqual(#logged.warn, 1)
        assertTruthy(logged.warn[1]:find("not a function", 1, true))
    end)

    it("SetDebug adds a traceback and still preserves args and returns", function()
        local LAC = LibApiCompose
        local ok, err, okArgs, x, y, z
        local logged = withLogger(function()
            LAC.SetDebug(true)
            assertEqual(LAC.IsDebug(), true)
            ok, err = LAC.SafeCallMulti(function(a, b)
                if a == 1 and b == nil then
                    error("traced", 0)
                end
            end, 1, nil)
            okArgs, x, y, z = LAC.SafeCallMulti(function(...)
                return ...
            end, "a", nil, "c")
        end)
        assertEqual(ok, false)
        assertEqual(err, "traced")
        assertEqual(#logged.warn, 1)
        assertTruthy(logged.warn[1]:find("traced", 1, true))
        assertTruthy(logged.warn[1]:find("traceback", 1, true), "expected a traceback in the log")
        assertEqual(okArgs, true)
        assertEqual(x, "a")
        assertEqual(y, nil)
        assertEqual(z, "c")
    end)

    it("SafeCallMulti preserves trailing nils", function()
        local LAC = LibApiCompose
        local function count(...)
            return select("#", ...)
        end
        assertEqual(
            count(LAC.SafeCallMulti(function()
                return 1, nil, nil
            end)),
            4
        )
    end)

    it("SelfTest lists ZOS symbols missing on this client", function()
        local LAC = LibApiCompose
        local function has(list, name)
            for _, value in ipairs(list) do
                if value == name then
                    return true
                end
            end
            return false
        end
        local result = LAC.SelfTest()
        assertEqual(result.total, #LAC._internal.ZOS_SYMBOLS)
        assertEqual(result.ok + #result.missing, result.total)
        -- The mock stubs every function the library calls; it only leaves out some house-bank
        -- and currency constants to exercise the "constant missing on this client" paths.
        for _, name in ipairs(result.missing) do
            assertTruthy(name:match("^BAG_HOUSE_BANK_") or name:match("^CURT_"), "mock is missing " .. name)
        end
        local saved = GetItemInfo
        _G.GetItemInfo = nil
        local broken = LAC.SelfTest()
        _G.GetItemInfo = saved
        assertEqual(has(broken.missing, "GetItemInfo"), true)
        assertEqual(#broken.missing, #result.missing + 1)
    end)

    it("NonEmpty maps empty strings to nil", function()
        local LAC = LibApiCompose
        assertEqual(LAC.NonEmpty(""), nil)
        assertEqual(LAC.NonEmpty("x"), "x")
        assertEqual(LAC.NonEmpty(nil), nil)
        assertEqual(LAC.NonEmpty(5), nil)
    end)

    it("SlotKey is stable", function()
        local LAC = LibApiCompose
        assertEqual(LAC.SlotKey(1, 5), LAC.KEY_STRIDE + 5)
        assertEqual(LAC.HotbarSlotKey(7, 3), 7 * LAC.KEY_STRIDE + 3)
    end)

    it("SlotKey does not collide for craft-bag item ids", function()
        local LAC = LibApiCompose
        assertTruthy(LAC.SlotKey(5, 150000) ~= LAC.SlotKey(6, 50000))
        assertTruthy(LAC.SlotKey(BAG_VIRTUAL, 999999) < LAC.SlotKey(BAG_VIRTUAL + 1, 0))
    end)

    it("AtLeast compares the encoded AddOnVersion", function()
        local LAC = LibApiCompose
        local saved = LAC.ADDON_VERSION
        LAC.ADDON_VERSION = 10203
        assertEqual(LAC.AtLeast(10203), true)
        assertEqual(LAC.AtLeast(10000), true)
        assertEqual(LAC.AtLeast(10300), false)
        LAC.ADDON_VERSION = saved
    end)

    it("FormatName strips grammar suffixes without zo_strformat", function()
        local LAC = LibApiCompose
        assertEqual(LAC.FormatName("Mirri Elendis^F"), "Mirri Elendis")
        assertEqual(LAC.FormatName("Bear^n"), "Bear")
        assertEqual(LAC.FormatName("Plain"), "Plain")
        assertEqual(LAC.FormatName(nil), nil)
    end)

    it("FormatName prefers zo_strformat when present", function()
        local LAC = LibApiCompose
        _G.zo_strformat = function(_, name)
            return "Z:" .. name
        end
        local out = LAC.FormatName("Bear^n")
        _G.zo_strformat = nil
        assertEqual(out, "Z:Bear^n")
    end)

    it("LowerName prefers zo_strlower when present", function()
        local LAC = LibApiCompose
        assertEqual(LAC.LowerName("ABC"), "abc")
        _G.zo_strlower = function(s)
            return "zl:" .. s
        end
        local out = LAC.LowerName("ABC")
        _G.zo_strlower = nil
        assertEqual(out, "zl:ABC")
    end)
end)
