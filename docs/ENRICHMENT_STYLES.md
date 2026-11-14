# Enrichment styles

| Style | Pattern | LibApiCompose |
|-------|---------|---------------|
| A. Flat index-list | GetNum + GetAt(i) | `ForIndex` / `MapIndex`; `BagSlot.ForBag` / `MapBag` |
| B. Nested index | Multi-level indices | `NestedFor` / `NestedMap` |
| C. Id-lookup compose | id → many ZOS calls | `Collectible.Compose`, `ItemLink.ComposeOnUse` |
| D. Slot/bag compose | bag+slot | `BagSlot.Compose`, `BagSlot.ComposeWorn`, `Gear.ComposeFromSlot` |
| E. Hotbar/quickslot | slot + hotbar category | `Quickslot.Compose`, `Quickslot.ComposeWheel` |
| F. Unit/tag | unitTag buffs/stats | Primitives only; domain deferred |
| G. Aggregate | Walk → list/summary | Collectible category lists; `ForLinked` |
| H. Product policy | FSM / affinity / junk thresholds | **Stay in product** |

## Deferred (CM-heavy)

Skills+morphs, Armory builds, Achievements trees, World/skyshards/lore, Crafting knowledge, Appearance, PvP/pledges.

## Stay in product

ECL park/guard/PressWatch; EVJ PA pin + thresholds; EAP affinity/writ/channels; EFC plan favorites.
