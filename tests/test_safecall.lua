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

    it("SlotKey is stable", function()
        local LAC = LibApiCompose
        assertEqual(LAC.SlotKey(1, 5), 100005)
        assertEqual(LAC.HotbarSlotKey(7, 3), 700003)
    end)
end)
