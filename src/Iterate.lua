-- LibApiCompose — Iterate primitives (styles A, B, G)

local LAC = LibApiCompose
LAC.Iterate = LAC.Iterate or {}
local Iterate = LAC.Iterate

--- Flat index walk: for i = 1, getNum() do fn(i, getAt(i)?) end
--- getAt is optional; when present it is invoked with SafeCallMulti when needMulti is true
--- (up to 8 return values are forwarded). Errors in fn itself are not caught.
function Iterate.ForIndex(getNum, getAt, fn, needMulti)
    if not fn then
        return
    end
    local n = 0
    if getNum then
        n = LAC.SafeCall(getNum) or 0
    end
    for i = 1, n do
        if getAt then
            if needMulti then
                local ok, a, b, c, d, e, f, g, h = LAC.SafeCallMulti(getAt, i)
                if ok then
                    fn(i, a, b, c, d, e, f, g, h)
                end
            else
                fn(i, LAC.SafeCall(getAt, i))
            end
        else
            fn(i)
        end
    end
end

--- Map 1..getNum() through mapFn(i, ...) → list of non-nil results.
function Iterate.MapIndex(getNum, getAt, mapFn, needMulti)
    local list = {}
    Iterate.ForIndex(getNum, getAt, function(i, ...)
        if not mapFn then
            return
        end
        local rec = mapFn(i, ...)
        if rec ~= nil then
            list[#list + 1] = rec
        end
    end, needMulti)
    return list
end

--- Nested index walk. levels is an array of { getNum = fn(parentIndices...) }.
--- fn(i1, i2, ..., iN) is called for every leaf index tuple.
--- Example: NestedFor({ { getNum = GetNumSkillTypes }, { getNum = GetNumSkillLines } }, fn)
function Iterate.NestedFor(levels, fn)
    if not levels or #levels == 0 or not fn then
        return
    end

    local function walk(depth, indices)
        local level = levels[depth]
        if not level or not level.getNum then
            return
        end
        local n = LAC.SafeCall(level.getNum, unpack(indices)) or 0
        for i = 1, n do
            local nextIndices = {}
            for j = 1, #indices do
                nextIndices[j] = indices[j]
            end
            nextIndices[#nextIndices + 1] = i
            if depth == #levels then
                fn(unpack(nextIndices))
            else
                walk(depth + 1, nextIndices)
            end
        end
    end

    walk(1, {})
end

--- Collect NestedFor results via mapFn(indices...).
function Iterate.NestedMap(levels, mapFn)
    local list = {}
    Iterate.NestedFor(levels, function(...)
        if not mapFn then
            return
        end
        local rec = mapFn(...)
        if rec ~= nil then
            list[#list + 1] = rec
        end
    end)
    return list
end

Iterate.MAX_LINKED_STEPS = 100000

--- Linked-list walker: getNext(nil) returns the first id, getNext(id) the next, nil ends.
--- Collects mapFn(id) results (non-nil) or the ids themselves when mapFn is nil.
--- maxSteps (default Iterate.MAX_LINKED_STEPS) guards against cycles; hitting it is logged.
function Iterate.ForLinked(getNext, mapFn, maxSteps)
    local list = {}
    if not getNext then
        return list
    end
    maxSteps = maxSteps or Iterate.MAX_LINKED_STEPS
    local id = LAC.SafeCall(getNext, nil)
    local guard = 0
    while id and guard < maxSteps do
        guard = guard + 1
        if mapFn then
            local rec = mapFn(id)
            if rec ~= nil then
                list[#list + 1] = rec
            end
        else
            list[#list + 1] = id
        end
        id = LAC.SafeCall(getNext, id)
    end
    if id and guard >= maxSteps then
        LAC.DebugPrint("ITERATE", "ForLinked stopped at maxSteps=" .. tostring(maxSteps))
    end
    return list
end

-- Aliases on LAC root for discoverability
LAC.ForIndex = Iterate.ForIndex
LAC.MapIndex = Iterate.MapIndex
LAC.NestedFor = Iterate.NestedFor
LAC.NestedMap = Iterate.NestedMap
LAC.ForLinked = Iterate.ForLinked
