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

    it("ForLinked walks until nil", function()
        local LAC = LibApiCompose
        local chain = { [0] = 1, [1] = 2, [2] = 3 }
        local function getNext(id)
            if id == nil then
                return chain[0]
            end
            return chain[id]
        end
        local list = LAC.ForLinked(getNext, function(id)
            return id
        end)
        assertEqual(#list, 3)
        assertEqual(list[1], 1)
        assertEqual(list[3], 3)
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
        local list = LAC.ForLinked(function(id)
            if id == nil then
                return 1
            end
            return id == 1 and 2 or 1
        end, nil, 5)
        assertEqual(#list, 5)
    end)
end)
