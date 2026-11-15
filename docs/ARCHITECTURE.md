# Architecture — LibApiCompose

Read-only ESO library: canonical `SafeCall` / `SafeCallMulti`, index walkers, and shared compose/enrich records. See [ARCHITECTURE_DECISIONS.md](ARCHITECTURE_DECISIONS.md) for why.

## Load order

Manifest `LibApiCompose.txt` (all files load eagerly; no lazy modules):

1. `src/Core.lua` — global `LibApiCompose` / `LAC`, SafeCall*, logging, keys, ClearCache, SelfTest
2. `src/Iterate.lua` — ForIndex / MapIndex / NestedFor / NestedMap / ForLinked / MapLinked
3. `src/ItemLink.lua` — link-based item compose + OnUse preview (shared item-type helpers)
4. `src/BagSlot.lua` — bag/slot snapshot + bag walkers
5. `src/Gear.lua` — gear triage on a BagSlot or ItemLink record
6. `src/Collectible.lua` — collectible id + category lists (registers cache-invalidation events)
7. `src/Quickslot.lua` — utility wheels
8. `src/Hotbar.lua` — skill bars
9. `src/Companion.lua` — active + roster
10. `src/Unit.lua` — unit tag snapshot
11. `src/Currency.lua` — currency amounts by location
12. `src/Skill.lua` — skill lines and abilities
13. `src/Buff.lua` — active effects on a unit
14. `src/Symbols.lua` — generated list of ZOS symbols for `LAC.SelfTest()`

Ready when files finish loading. Consumers `## DependsOn: LibApiCompose>=10000` (encoded AddOnVersion for `v1.0.0`).

## Consumer flow

```text
raw handles  →  LAC.*.Compose(...)  →  decide in product  →  raw fields on record  →  ZOS / product write APIs
```

Compose is for reading and deciding. Identity fields on the record (`bagId`, `slotIndex`, `id`, `link`, `actionType`, `actionId`, …) are for acting. There is no `Decompose*` API.

## Modules

| Module | Role |
|--------|------|
| Core | SafeCall, SafeCallMulti, SetDebug, SelfTest, SlotKey, HotbarSlotKey, NONE, AtLeast, FormatName, LowerName, NonEmpty, ClearCache |
| Iterate | Flat / nested / linked-list walks with early exit (styles A, B, G) |
| ItemLink | Item facts from a link; OnUse ability preview |
| BagSlot | Inventory snapshot (identity, uniqueId, quality, locks, flags, value) + ForBag / ForBags / MapBag / ComposeWorn |
| Gear | Set / trait / enchant / junk-eligibility facts from a slot or a link (same shape for non-gear) |
| Collectible | Id compose + unlocked-by-category + name index / FindByName |
| Quickslot | Utility-wheel slot (`isEmpty`, cooldown, current slot) + collectible fallback + ComposeWheel |
| Hotbar | Skill-bar slot (ability / crafted ability, cooldown) + ComposeBar |
| Companion | Active (level, rapport) or pending companion + roster |
| Unit | Name, level, class, race, alliance, power pools, state flags |
| Currency | Amount / max / name / icon per currency and location |
| Skill | Line and ability records, nested walks |
| Buff | Active effects (13-return `GetUnitBuffInfo`) |

## Thin passthrough

```lua
local level = LibApiCompose.SafeCall(GetUnitLevel, "player")
```

No compose module required for the safety standard.

## Caching

- Bag / quickslot / hotbar / item link / companion / unit / currency / skill / buff: always fresh Compose
- Collectible static facts (name, icon, category): memo per id until `LAC.ClearCache()`
- Collectible volatile facts (unlocked, active, blocked, cooldown, nickname): always read live
- Collectible unlocked-by-category id lists: memo, cleared by the lib's own collection events
  (`EVENT_COLLECTION_UPDATED`, `EVENT_COLLECTIBLES_UNLOCK_STATE_CHANGED`, `EVENT_COLLECTIBLE_UPDATED`,
  registered only when defined) or `LAC.ClearCache()`
- Collectible name indexes: memo until `LAC.ClearCache()` (independent of unlock state)
- Every record, list and map returned is freshly built; mutating it never touches the cache
- Event registrations exist only for self-invalidation (ADR-008 amendment); no callback bus
