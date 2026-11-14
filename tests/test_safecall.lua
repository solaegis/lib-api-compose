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

    it("SafeCallMulti logs a traceback but returns the raw error when LibDebugLogger is present", function()
        local LAC = LibApiCompose
        local logged = {}
        _G.LibDebugLogger = {
            Create = function()
                return {
                    Debug = function(_, msg)
                        logged[#logged + 1] = msg
                    end,
                }
            end,
        }
        LAC._logger = nil
        local ok, err = LAC.SafeCallMulti(function(a, b)
            if a == 1 and b == nil then
                error("traced", 0)
            end
        end, 1, nil)
        local okArgs, x, y, z = LAC.SafeCallMulti(function(...)
            return ...
        end, "a", nil, "c")
        _G.LibDebugLogger = nil
        LAC._logger = nil
        assertEqual(ok, false)
        assertEqual(err, "traced")
        assertEqual(#logged, 1)
        assertTruthy(logged[1]:find("traced", 1, true))
        assertTruthy(logged[1]:find("traceback", 1, true), "expected a traceback in the log")
        assertEqual(okArgs, true)
        assertEqual(x, "a")
        assertEqual(y, nil)
        assertEqual(z, "c")
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
