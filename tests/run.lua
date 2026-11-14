#!/usr/bin/env lua
-- Plain Lua test runner for LibApiCompose.

local function scriptRoot()
    local info = debug.getinfo(1, "S")
    local src = info and info.source or ""
    src = src:gsub("^@", "")
    local dir = src:match("^(.*)/") or "."
    return dir:match("^(.*)/tests$") or (dir .. "/..")
end

local ROOT = scriptRoot()
package.path = ROOT .. "/tests/?.lua;" .. ROOT .. "/tests/?/init.lua;" .. ROOT .. "/?.lua;" .. (package.path or "")

local suites = {}
local currentSuite = nil
local failures = {}
local passes = 0
local total = 0

local function fail(msg, level)
    level = (level or 1) + 1
    local info = debug.getinfo(level, "Sl")
    error({
        message = msg,
        file = info and info.short_src or "?",
        line = info and info.currentline or 0,
    }, 0)
end

function describe(name, fn)
    table.insert(suites, { name = name, fn = fn, cases = {} })
end

function it(name, fn)
    if not currentSuite then
        error("it() outside describe()", 2)
    end
    table.insert(currentSuite.cases, { name = name, fn = fn })
end

function assertEqual(actual, expected, msg)
    if actual ~= expected then
        fail(
            string.format(
                "%s\n  expected: %s\n  actual:   %s",
                msg or "assertEqual failed",
                tostring(expected),
                tostring(actual)
            ),
            2
        )
    end
end

function assertTruthy(actual, msg)
    if not actual then
        fail(msg or "expected truthy", 2)
    end
end

function assertFalsy(actual, msg)
    if actual then
        fail(msg or "expected falsy", 2)
    end
end

-- Load mock ESO + library sources
local mock = require("mock.eso")
mock.reset()

dofile(ROOT .. "/src/Core.lua")
dofile(ROOT .. "/src/Iterate.lua")
dofile(ROOT .. "/src/BagSlot.lua")
dofile(ROOT .. "/src/Gear.lua")
dofile(ROOT .. "/src/Collectible.lua")
dofile(ROOT .. "/src/Quickslot.lua")
dofile(ROOT .. "/src/ItemLink.lua")
dofile(ROOT .. "/src/Companion.lua")

_G.mock = mock

dofile(ROOT .. "/tests/test_safecall.lua")
dofile(ROOT .. "/tests/test_bagslot.lua")
dofile(ROOT .. "/tests/test_iterate.lua")
dofile(ROOT .. "/tests/test_collectible.lua")
dofile(ROOT .. "/tests/test_quickslot.lua")

for _, suite in ipairs(suites) do
    currentSuite = suite
    suite.fn()
    currentSuite = nil
end

for _, suite in ipairs(suites) do
    print(suite.name)
    for _, case in ipairs(suite.cases) do
        total = total + 1
        local ok, err = pcall(case.fn)
        if ok then
            passes = passes + 1
            print("  ✓ " .. case.name)
        else
            local msg = err
            if type(err) == "table" then
                msg = string.format("%s:%s: %s", tostring(err.file), tostring(err.line), tostring(err.message))
            end
            table.insert(failures, suite.name .. " / " .. case.name .. " — " .. tostring(msg))
            print("  ✗ " .. case.name)
        end
    end
end

print(string.format("\n%d/%d passed", passes, total))
if #failures > 0 then
    print("\nFailures:")
    for _, f in ipairs(failures) do
        print("  - " .. f)
    end
    os.exit(1)
end
