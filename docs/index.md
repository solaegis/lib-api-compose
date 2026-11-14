# LibApiCompose

**LibApiCompose** (`LAC`) is a read-only library for Elder Scrolls Online PC addons. It gives you:

- **A canonical `SafeCall` / `SafeCallMulti`** — one tested way to call ZOS APIs that never throws, keeps
  `nil` holes in multiple returns, and soft-fails when an API is missing on the client.
- **Iteration helpers** — flat, nested and linked-list walks, plus bag walkers that handle 0-based slots and
  the craft bag for you.
- **Compose records** — one call turns raw handles (`bagId, slotIndex`, a collectible id, a hotbar slot, an
  item link) into a plain Lua table of the facts you usually need, while keeping the raw handles on the record
  so you can act on it.

```lua
local LAC = LibApiCompose

-- Find unlocked, unbound gear in the backpack worth researching.
local candidates = LAC.BagSlot.MapBag(BAG_BACKPACK, function(slot)
    if not slot.isGear or slot.isLocked then
        return nil
    end
    local gear = LAC.Gear.ComposeFromSlot(slot.bagId, slot.slotIndex)
    if gear and gear.isResearchable then
        return gear
    end
    return nil
end)

for _, gear in ipairs(candidates) do
    d(string.format("%s — %s", gear.link, gear.trait.name or "?"))
end
```

## What it is not

- **Not a write API.** LAC never calls `Use*`, `Set*`, `Request*` or protected functions. You decide and act in
  your own addon with the identity fields on each record (`bagId`, `slotIndex`, `actionId`, …).
- **Not a full ZOS catalog.** It covers the domains several solaegis addons share: bag slots, gear,
  collectibles, quickslots, item on-use effects and companions.
- **Not stateful.** No SavedVariables, no callbacks, no UI.

## Where to go next

| I want to… | Read |
|---|---|
| Add LAC to my addon | [Installation](getting-started/installation.md) |
| See it working in five minutes | [Quick start](getting-started/quickstart.md) |
| Understand records and the compose → decide → act flow | [Core concepts](guides/concepts.md) |
| Look up a function or field | [API reference](reference/index.md) |
| Copy a working pattern | [Recipes](guides/recipes.md) |
| Fix "my addon won't load" | [Troubleshooting](guides/troubleshooting.md) |
| Contribute to the library | [Contributing](contributing/index.md) |

## Compatibility

| | |
|---|---|
| Game | Elder Scrolls Online, **PC/Mac only** (not console) |
| Lua | 5.1 semantics (ESO's runtime); no `goto` |
| API version | `101051 101050` (see the manifest) |
| Hard dependencies | none |
| Optional dependencies | [LibDebugLogger](https://www.esoui.com/downloads/info2275-LibDebugLogger.html) — error logging with tracebacks |
| Global | `LibApiCompose` (convention: `local LAC = LibApiCompose`) |
