-- LibApiCompose — Iterate primitives (styles A, B, G)
--
-- Counts and lookups go through SafeCall; callbacks are not protected.
-- Every walker stops early when its callback returns true.

local LAC = LibApiCompose
LAC.Iterate = LAC.Iterate or {}
local Iterate = LAC.Iterate

-- Forwards every getAt return to fn without building a table; skips the index when getAt failed.
local function forward(fn, i, ok, ...)
    if ok then
        return fn(i, ...)
    end
    return nil
end

local function forwardFirst(fn, i, ok, first)
    if ok then
        return fn(i, first)
    end
    return nil
end

--- Flat index walk: for i = 1, getNum() do fn(i, getAt(i)?) end
--- getAt is optional. needMulti forwards every return value of getAt; otherwise only the first.
--- Indices where getAt errors are skipped. Return true from fn to stop.
--- Returns the number of fn calls made.
function Iterate.ForIndex(getNum, getAt, fn, needMulti)
    if not fn then
        return 0
    end
    local n = 0
    if getNum then
        n = tonumber(LAC.SafeCall(getNum)) or 0
    end
    local visited = 0
    for i = 1, n do
        local stop
        if not getAt then
            visited = visited + 1
            stop = fn(i)
        elseif needMulti then
            visited = visited + 1
            stop = forward(fn, i, LAC.SafeCallMulti(getAt, i))
        else
            visited = visited + 1
            stop = forwardFirst(fn, i, LAC.SafeCallMulti(getAt, i))
        end
        if stop == true then
            break
        end
    end
    return visited
end

--- Map 1..getNum() through mapFn(i, ...) → list of non-nil results.
function Iterate.MapIndex(getNum, getAt, mapFn, needMulti)
    local list = {}
    if not mapFn then
        return list
    end
    Iterate.ForIndex(getNum, getAt, function(i, ...)
        local rec = mapFn(i, ...)
        if rec ~= nil then
            list[#list + 1] = rec
        end
    end, needMulti)
    return list
end

--- Nested index walk. levels is an array of { getNum = fn(parentIndices...) }.
--- fn(i1, i2, ..., iN) is called for every leaf index tuple; return true to stop the whole walk.
--- Example: NestedFor({ { getNum = GetNumSkillTypes }, { getNum = GetNumSkillLines } }, fn)
function Iterate.NestedFor(levels, fn)
    if not levels or #levels == 0 or not fn then
        return
    end
    local depthCount = #levels
    local indices = {}

    local function walk(depth)
        local level = levels[depth]
        if not level or not level.getNum then
            return false
        end
        local n = tonumber(LAC.SafeCall(level.getNum, unpack(indices, 1, depth - 1))) or 0
        for i = 1, n do
            indices[depth] = i
            if depth == depthCount then
                if fn(unpack(indices, 1, depthCount)) == true then
                    return true
                end
            elseif walk(depth + 1) then
                return true
            end
        end
        indices[depth] = nil
        return false
    end

    walk(1)
end

--- Collect NestedFor results via mapFn(indices...).
function Iterate.NestedMap(levels, mapFn)
    local list = {}
    if not mapFn then
        return list
    end
    Iterate.NestedFor(levels, function(...)
        local rec = mapFn(...)
        if rec ~= nil then
            list[#list + 1] = rec
        end
    end)
    return list
end

Iterate.MAX_LINKED_STEPS = 100000

--- Linked-list walk: getNext(nil) returns the first id, getNext(id) the next.
--- The chain ends on nil, on 0 (many ZOS "next" APIs end with 0; pass zeroIsValid = true for
--- chains where 0 is a real id) or when getNext returns the id it was given.
--- fn(id) is called per id; return true to stop. maxSteps (default Iterate.MAX_LINKED_STEPS)
--- guards against cycles; hitting it is logged. Returns the number of ids visited.
function Iterate.ForLinked(getNext, fn, maxSteps, zeroIsValid)
    if not getNext or not fn then
        return 0
    end
    maxSteps = maxSteps or Iterate.MAX_LINKED_STEPS
    local visited = 0
    local id = LAC.SafeCall(getNext, nil)
    while id ~= nil and (zeroIsValid or id ~= 0) do
        if visited >= maxSteps then
            LAC._internal.reportOnce("ITERATE", "maxSteps", "ForLinked stopped at maxSteps=" .. tostring(maxSteps))
            break
        end
        visited = visited + 1
        if fn(id) == true then
            break
        end
        local nextId = LAC.SafeCall(getNext, id)
        if nextId == id then
            break
        end
        id = nextId
    end
    return visited
end

--- Collect a linked-list walk: mapFn(id) results (non-nil), or the ids themselves when mapFn is nil.
function Iterate.MapLinked(getNext, mapFn, maxSteps, zeroIsValid)
    local list = {}
    Iterate.ForLinked(getNext, function(id)
        local rec = id
        if mapFn then
            rec = mapFn(id)
        end
        if rec ~= nil then
            list[#list + 1] = rec
        end
    end, maxSteps, zeroIsValid)
    return list
end

-- Aliases on LAC root for discoverability
LAC.ForIndex = Iterate.ForIndex
LAC.MapIndex = Iterate.MapIndex
LAC.NestedFor = Iterate.NestedFor
LAC.NestedMap = Iterate.NestedMap
LAC.ForLinked = Iterate.ForLinked
LAC.MapLinked = Iterate.MapLinked
