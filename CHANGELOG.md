# Changelog

## [Unreleased]

First release candidate. Nothing has been tagged yet; the list below is what `1.0.0` will contain.

### Added

- Library bootstrap: `IsLibrary: true`, standalone PC manifest
- Canonical `SafeCall` / `SafeCallMulti`: nil-hole preserving, allocation-free; with LibDebugLogger each distinct
  failure (including a call to a missing function) is logged once; `SetDebug(true)` adds tracebacks
- Core: `SlotKey` / `HotbarSlotKey` (2^24 stride, craft-bag safe), `AtLeast`, `FormatName`, `LowerName`,
  `NonEmpty`, `ClearCache`, `SetDebug` / `IsDebug`, `SelfTest` (lists ZOS symbols missing on the client)
- Iterate: `ForIndex`, `MapIndex`, `NestedFor`, `NestedMap`, `ForLinked`, `MapLinked`. Every `For*` walker stops
  when its callback returns `true`; `ForIndex(needMulti)` forwards every return value; linked walks end on
  `nil`, `0` or a repeated id and are bounded by `maxSteps`
- ItemLink: `Compose` (item facts from a link alone), `ParseId`, `ComposeOnUse`
- BagSlot: `Compose` (identity incl. `uniqueId`, both qualities, stack, value, equip/bind type, condition,
  requirements, `isPlayerLocked` / `isSlotLocked` / `isLocked`, junk/bound/stolen/unique/armory/usable flags,
  set-collection status), `ForBag` (with `opts.filter`), `ForBags`, `MapBag`, `ComposeWorn` (player or
  companion); craft bag and guild bank walks; `LAC.BAGS.BANK` / `HOUSE_BANKS`
- Gear: `ComposeFromSlot` and `ComposeFromLink` (set incl. perfected count, trait, intricate/ornate, research,
  armor/weapon type, enchant with charges, `canMarkJunk`)
- Collectible: `Compose` (incl. unlock state, blocked, cooldown; optional description and link),
  `ComposeUnlockedByCategory`, `IndexByName`, `FindByName`, `InvalidateLists`; static-fact memo + live volatile
  state + event-driven list invalidation
- Quickslot (utility wheels): `Compose` (with `isEmpty`, `isCurrent`, cooldown, item link), `ComposeWheel` for
  the quickslot, ally, emote, memento and tool wheels, `IsWheel`, `Args`, `ActionArgs`
- Hotbar (skill bars): `ComposeSlot`, `ComposeBar` (ability id, scribed-ability resolution, cooldown)
- Companion: `ComposeActive` (level, XP, rapport; optional pending companion), `ComposeRoster`
- Unit: `Compose` (name, level, CP, class, race, alliance, state flags, power pools)
- Currency: `Compose`, `ComposeAll` by location
- Skill: `ComposeLine`, `ComposeAbility`, `ComposeLines`, `ComposeAbilities`, `ForEachAbility`
- Buff: `ComposeAll`, `Find`
- Semver Version + encoded-integer AddOnVersion (committed integer for dev installs)
- Docs: developer site (MkDocs), ARCHITECTURE, ARCHITECTURE_DECISIONS (ADR-001..012), enrichment styles
- Unit tests with a plain Lua mock harness; CI on Lua 5.1 + LuaJIT
- ZOS API drift check: every game symbol the library reads, and the return count of every multi-return mock
  stub, is verified against ZOS's `ESOUIDocumentation.txt` in `task test` and CI

### Fixed (found in pre-release review)

- `BagSlot` `isLocked` read `GetItemInfo`'s transient slot lock and never the player's lock toggle, so
  player-locked items looked unlocked. It is now `isPlayerLocked or isSlotLocked`, with both exposed
- `BagSlot` `displayQuality` held the functional quality (`GetItemInfo` returns nine values, not eight)
- `ForLinked` treated `0` as an id and ran to the 100 000-step guard on 0-terminated iterators
- `ForIndex(needMulti)` dropped every return value after the eighth
- `Collectible.Compose` returned (and cached) a record for ids that are not collectibles
- `Quickslot.ComposeWheel` walked slots 1..8 for skill bars; skill bars now have `Hotbar.ComposeBar`
- String fields were `""` instead of `nil` when the game had no value
- Collection events needlessly dropped the name index
