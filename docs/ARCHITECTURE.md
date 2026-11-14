# Architecture — LibApiCompose

Read-only ESO library: canonical `SafeCall` / `SafeCallMulti`, index walkers, and shared compose/enrich records. See [ARCHITECTURE_DECISIONS.md](ARCHITECTURE_DECISIONS.md) for why.

## Load order

Manifest `LibApiCompose.txt` (all files load eagerly; no lazy modules):

1. `src/Core.lua` — global `LibApiCompose` / `LAC`, SafeCall*, keys, ClearCache
2. `src/Iterate.lua` — ForIndex / MapIndex / NestedMap / ForLinked
3. `src/BagSlot.lua` — bag/slot snapshot + bag walkers
4. `src/Gear.lua` — gear triage on BagSlot
5. `src/Collectible.lua` — collectible id + category lists (registers cache-invalidation events)
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
| Core | SafeCall, SafeCallMulti, SlotKey, HotbarSlotKey, NONE, AtLeast, FormatName, LowerName, ClearCache |
| Iterate | Flat / nested / linked-list walks (styles A, B, G) |
| BagSlot | Inventory snapshot (identity, uniqueId, quality, flags, value) + ForBag / MapBag / ComposeWorn |
| Gear | Set / trait / enchant / junk-eligibility facts (gear only; same shape for non-gear) |
| Collectible | Id compose + unlocked-by-category + name index |
| Quickslot | Wheel/hotbar slot (`isEmpty`) + collectible fallback + ComposeWheel |
| ItemLink | OnUse ability preview (hasAbility, header, description, cooldown) |
| Companion | Active companion + roster |

## Thin passthrough

```lua
local level = LibApiCompose.SafeCall(GetUnitLevel, "player")
```

No compose module required for the safety standard.

## Caching

- Bag / quickslot / item link / companion: always fresh Compose (high churn)
- Collectible static facts (name, icon, category): memo per id until `LAC.ClearCache()`
- Collectible volatile facts (unlocked, active, nickname): always read live
- Collectible unlocked-by-category id lists + name indexes: memo, cleared by the lib's own
  collection events (`EVENT_COLLECTION_UPDATED`, `EVENT_COLLECTIBLES_UNLOCK_STATE_CHANGED`,
  `EVENT_COLLECTIBLE_UPDATED`, registered only when defined) or `LAC.ClearCache()`
- Every record, list and map returned is freshly built; mutating it never touches the cache
- Event registrations exist only for self-invalidation (ADR-008 amendment); no callback bus
