# Changelog

## [Unreleased]

## [1.0.0] - unreleased

### Added

- Library bootstrap: `IsLibrary: true`, standalone PC manifest
- Canonical `SafeCall` / `SafeCallMulti` (nil-hole preserving; traceback logged when LibDebugLogger is present)
- Core: `SlotKey` / `HotbarSlotKey` (2^24 stride, craft-bag safe), `AtLeast`, `FormatName`, `LowerName`, `ClearCache`
- Iterate: `ForIndex`, `MapIndex`, `NestedFor`, `NestedMap`, `ForLinked` (with `maxSteps` guard)
- BagSlot: `Compose` (identity incl. `uniqueId`, quality, stack, value, equip type, requirements, lock/junk/bound/stolen flags), `ForBag`, `MapBag`, `ComposeWorn`
- Gear: `ComposeFromSlot` (set incl. perfected count, trait, research, enchant with `hasCharges`, `canMarkJunk`)
- Collectible: `Compose`, `ComposeUnlockedByCategory`, `IndexByName`, `InvalidateLists`; static-fact memo + live volatile state + event-driven list invalidation
- Quickslot: `Compose` (with `isEmpty`), `ComposeWheel`, `Args`, `ActionArgs`
- ItemLink: `ComposeOnUse` (`hasAbility`, `header`, `description`, `cooldown`, `remainingCooldown`)
- Companion: `ComposeActive`, `ComposeRoster`
- Semver Version + encoded-integer AddOnVersion (committed integer for dev installs)
- Docs: ARCHITECTURE, ARCHITECTURE_DECISIONS (ADR-001..012), enrichment styles
- Unit tests with a plain Lua mock harness mirroring real ZOS return shapes; CI on Lua 5.1 + LuaJIT
