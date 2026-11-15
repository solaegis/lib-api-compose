describe("Iterate", function()
    it("MapIndex builds a list", function()
        local LAC = LibApiCompose
        local function getNum()
            return 3
        end
        local function getAt(i)
            return i * 10
        end
        local list = LAC.MapIndex(getNum, getAt, function(i, v)
            return { i = i, v = v }
        end)
        assertEqual(#list, 3)
        assertEqual(list[2].v, 20)
    end)

    it("MapLinked walks until nil", function()
        local LAC = LibApiCompose
        local chain = { [0] = 1, [1] = 2, [2] = 3 }
        local function getNext(id)
            if id == nil then
                return chain[0]
            end
            return chain[id]
        end
        local list = LAC.MapLinked(getNext, function(id)
            return id * 2
        end)
        assertEqual(#list, 3)
        assertEqual(list[1], 2)
        assertEqual(list[3], 6)
        assertEqual(#LAC.MapLinked(getNext), 3)
    end)

    it("ForLinked visits ids, counts them and stops early", function()
        local LAC = LibApiCompose
        local function getNext(id)
            local nextId = (id or 0) + 1
            return nextId <= 5 and nextId or nil
        end
        local seen = {}
        assertEqual(
            LAC.ForLinked(getNext, function(id)
                seen[#seen + 1] = id
            end),
            5
        )
        assertEqual(#seen, 5)
        assertEqual(
            LAC.ForLinked(getNext, function(id)
                return id == 2
            end),
            2
        )
    end)

    it("ForLinked treats 0 as the end of the chain unless zeroIsValid", function()
        local LAC = LibApiCompose
        -- Shape of GetNextAchievementInLine: 0 means "no next".
        local function zeroTerminated(id)
            if id == nil then
                return 10
            end
            return id == 10 and 11 or 0
        end
        assertEqual(#LAC.MapLinked(zeroTerminated), 2)
        -- With zeroIsValid a repeated id still ends the walk (no runaway to maxSteps).
        local list = LAC.MapLinked(zeroTerminated, nil, nil, true)
        assertEqual(#list, 3)
        assertEqual(list[3], 0)
    end)

    it("NestedMap walks two levels", function()
        local LAC = LibApiCompose
        local list = LAC.NestedMap({
            {
                getNum = function()
                    return 2
                end,
            },
            {
                getNum = function(a)
                    return a -- level2 count = parent index
                end,
            },
        }, function(a, b)
            return { a = a, b = b }
        end)
        -- (1,1) then (2,1),(2,2) => 3
        assertEqual(#list, 3)
    end)

    it("ForIndex forwards multiple returns with needMulti", function()
        local LAC = LibApiCompose
        local got = {}
        LAC.ForIndex(function()
            return 2
        end, function(i)
            return i, nil, "x" .. i
        end, function(i, a, b, c)
            got[i] = { a = a, b = b, c = c }
        end, true)
        assertEqual(got[2].a, 2)
        assertEqual(got[2].b, nil)
        assertEqual(got[2].c, "x2")
    end)

    it("ForIndex survives a failing getNum", function()
        local LAC = LibApiCompose
        local calls = 0
        LAC.ForIndex(
            function()
                error("no")
            end,
            nil,
            function()
                calls = calls + 1
            end
        )
        assertEqual(calls, 0)
    end)

    it("ForLinked stops at maxSteps on a cycle", function()
        local LAC = LibApiCompose
        local list = LAC.MapLinked(function(id)
            if id == nil then
                return 1
            end
            return id == 1 and 2 or 1
        end, nil, 5)
        assertEqual(#list, 5)
    end)

    it("ForIndex forwards more than 8 return values", function()
        local LAC = LibApiCompose
        local count, last = 0, nil
        LAC.ForIndex(function()
            return 1
        end, function()
            return 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13
        end, function(_, ...)
            count = select("#", ...)
            last = select(13, ...)
        end, true)
        assertEqual(count, 13)
        assertEqual(last, 13)
    end)

    it("ForIndex skips indices whose getAt errors, in both modes", function()
        local LAC = LibApiCompose
        local function getAt(i)
            if i == 2 then
                error("bad index")
            end
            return i
        end
        local function three()
            return 3
        end
        for _, needMulti in ipairs({ false, true }) do
            local seen = {}
            LAC.ForIndex(three, getAt, function(i)
                seen[#seen + 1] = i
            end, needMulti)
            assertEqual(#seen, 2)
            assertEqual(seen[2], 3)
        end
    end)

    it("ForIndex stops when fn returns true", function()
        local LAC = LibApiCompose
        local calls = 0
        LAC.ForIndex(
            function()
                return 10
            end,
            nil,
            function(i)
                calls = calls + 1
                return i == 3
            end
        )
        assertEqual(calls, 3)
    end)

    it("NestedFor walks three levels and stops the whole walk on true", function()
        local LAC = LibApiCompose
        local function two()
            return 2
        end
        local levels = { { getNum = two }, { getNum = two }, { getNum = two } }
        local tuples = LAC.NestedMap(levels, function(a, b, c)
            return a * 100 + b * 10 + c
        end)
        assertEqual(#tuples, 8)
        assertEqual(tuples[1], 111)
        assertEqual(tuples[8], 222)
        local calls = 0
        LAC.NestedFor(levels, function(a, b, c)
            calls = calls + 1
            return a == 1 and b == 2 and c == 1
        end)
        assertEqual(calls, 3)
    end)
end)
