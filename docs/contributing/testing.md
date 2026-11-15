# Testing

ESO's API isn't available outside the game, so unit tests run the real `src/` files against a mock of the ZOS
functions they call. CI runs the suite on Lua 5.1 and LuaJIT.

```bash
task test:unit        # tests only
task test             # tests + lint + format + validations
```

## How the harness works

`tests/run.lua`:

1. defines a tiny test DSL (`describe`, `it`, `assertEqual`, `assertTruthy`, `assertFalsy`);
2. loads `tests/mock/eso.lua`, which installs ZOS globals and exposes helpers as `mock`;
3. loads the files listed in `LibApiCompose.txt`, in manifest order — the same list the game loads;
4. discovers every `tests/test_*.lua` suite and runs every case, printing `✓` / `✗` and exiting non-zero on failure.

## The mock

`tests/mock/eso.lua` stubs only the APIs LAC calls, backed by in-memory tables you fill per test:

| Helper | Fills |
|---|---|
| `mock.reset()` | clears all fake state **and** calls `LibApiCompose.ClearCache()` |
| `mock.setItem(bagId, slotIndex, data)` | an item (`id`, `link`, `type`, `quality`, `stack`, `locked`, `junk`, `hasSet`, `traitType`, `enchantHeader`, …) |
| `mock.setBagSize(bagId, n)` | `GetBagSize` |
| `mock.setCollectible(id, data)` | `name`, `nickname`, `icon`, `category`, `unlocked`, `active` |
| `mock.setSlot(hotbarCategory, slotIndex, data)` | `type`, `id`, `name`, `texture`, `count`, `usable` |
| `mock.setCompanion({ defId, collectibleId })` | the summoned companion |
| `mock.fireEvent(eventCode, ...)` | calls handlers registered through the fake `EVENT_MANAGER` |
| `mock.registeredEvents()` | list of `{ namespace, event, fn }` registrations |

### Mocks must match the real return shape

This is the most important rule in the test suite. Every stub returns values **in the same order and number as
the real ZOS function**, with the real signature in a comment above it:

```lua
-- GetItemLinkOnUseAbilityInfo(link) -> hasAbility, abilityHeader, abilityDescription, cooldown,
--     hasScaling, minLevel, maxLevel, isChampionPoints, remainingCooldown
function _G.GetItemLinkOnUseAbilityInfo(link)
    if link == "|H0:item:1|h|h" then
        return true, "Header", "Description", 45000, false, 0, 0, false, 1000
    end
    return false, "", "", 0, false, 0, 0, false, 0
end
```

A mock shaped like the code under test proves nothing: before 1.0.0 the on-use mock returned an id first, the
code read it as an id, the test passed, and the field was wrong in game. Check the signature against the ESOUI
wiki or `/script d(GetX(...))` in game, and copy it into the comment.

Empty states should match too: ZOS usually returns `0` or `""`, not `nil`.

## Writing a test

```lua
describe("BagSlot", function()
    it("marks stolen items", function()
        mock.reset()
        mock.setItem(BAG_BACKPACK, 0, { id = 1, link = "|H0:item:1|h|h", stolen = true })
        local rec = LibApiCompose.BagSlot.Compose(BAG_BACKPACK, 0)
        assertEqual(rec.isStolen, true)
    end)
end)
```

- Start each case with `mock.reset()` so caches and fake state don't leak between cases.
- Assert the exact value (`assertEqual(x, true)`), not truthiness, for boolean fields.
- Test the empty/invalid handle (`nil` return) and the missing-API case for new fields.
- Restore any global you override (`_G.zo_strformat = nil` after the assertion).

## Adding a suite

1. Create `tests/test_<area>.lua`.
2. It is picked up automatically (the runner loads every `tests/test_*.lua`).
3. If you used new test-only globals, add them to the `files["tests/**/*.lua"]` block in `.luacheckrc`.

## Checking the mock against the real API

The mock is only as good as its signatures. `task dev:validate:zos` (part of `task test`) downloads ZOS's
`ESOUIDocumentation.txt` for the live API into `.cache/` and runs `scripts/zos-api.lua`, which fails when:

- a name in the `BEGIN ZOS API` block of `.luacheckrc` doesn't exist in that API version, or is no longer used;
- a mock stub of a multi-return function lacks a `-- returns: N` line matching the documented return count;
- `src/Symbols.lua` (the list `LAC.SelfTest()` checks in game) is stale — regenerate with `task dev:zos:write`.

Offline, the documentation checks are skipped with a warning; in CI a missing document fails the build.

## What unit tests can't cover

Green tests mean the logic is right *given the mock*. Before a release, also:

```text
task install:live, then /reloadui in game, then for example:
/script d(LibApiCompose.SelfTest())
/script d(LibApiCompose.BagSlot.Compose(BAG_BACKPACK, 0))
/script d(LibApiCompose.Quickslot.ComposeWheel().count)
/script d(LibApiCompose.Companion.ComposeActive())
```
