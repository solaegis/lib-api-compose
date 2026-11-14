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
end)
