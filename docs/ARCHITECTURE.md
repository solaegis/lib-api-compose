# Architecture — LibApiCompose

Read-only ESO library: canonical `SafeCall` / `SafeCallMulti`, index walkers, and shared compose/enrich records. See [ARCHITECTURE_DECISIONS.md](ARCHITECTURE_DECISIONS.md) for why.

## Load order

Manifest `LibApiCompose.txt` (all files load eagerly; no lazy modules):

1. `src/Core.lua` — global `LibApiCompose` / `LAC`, SafeCall*, keys, ClearCache
2. `src/Iterate.lua` — ForIndex / MapIndex / NestedMap / ForLinked
3. `src/BagSlot.lua` — bag/slot snapshot
4. `src/Gear.lua` — gear triage on BagSlot
5. `src/Collectible.lua` — collectible id + category lists
6. `src/Quickslot.lua` — utility wheel / hotbar slot
7. `src/ItemLink.lua` — OnUse preview
8. `src/Companion.lua` — active + roster

Ready when files finish loading. Consumers `## DependsOn: LibApiCompose>=10000` (encoded AddOnVersion for `v1.0.0`).

## Consumer flow

```text
raw handles  →  LAC.*.Compose(...)  →  decide in product  →  raw fields on record  →  ZOS / product write APIs
```

Compose is for reading and deciding. Identity fields on the record (`bagId`, `slotIndex`, `id`, `link`, `actionType`, `actionId`, …) are for acting. There is no `Decompose*` API.

## Modules

| Module | Role |
|--------|------|
| Core | SafeCall, SafeCallMulti, SlotKey, HotbarSlotKey, NONE, ClearCache |
| Iterate | Flat / nested / linked-list walks (styles A, B, G) |
| BagSlot | Inventory snapshot |
| Gear | Set / trait / junk-eligibility facts |
| Collectible | Id compose + unlocked-by-category + name index (memoized) |
| Quickslot | Wheel/hotbar slot + collectible icon fallback |
| ItemLink | OnUse ability preview |
| Companion | Active companion + roster |

## Thin passthrough

```lua
local level = LibApiCompose.SafeCall(GetUnitLevel, "player")
```

No compose module required for the safety standard.

## Caching

- Bag / quickslot: always fresh Compose (high churn)
- Collectible aggregates / by-id: memo until `LAC.ClearCache()`
- Never return the live cache table; lists/maps are copied out
- No lib-owned EVENT_MANAGER registrations — consumers invalidate
