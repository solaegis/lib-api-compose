# LibApiCompose

[![Version](https://img.shields.io/github/v/release/solaegis/lib-api-compose?include_prereleases&sort=semver&label=Version)](https://github.com/solaegis/lib-api-compose/releases)
[![ESO API](https://img.shields.io/badge/ESO_API-101051-blue)](https://github.com/solaegis/lib-api-compose)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)
[![Docs](https://img.shields.io/badge/docs-solaegis.github.io-orange)](https://solaegis.github.io/lib-api-compose/)

solaegis ESO **library**: canonical `SafeCall` / `SafeCallMulti`, index walkers, and shared compose/enrich helpers (item links, bags, gear, collectibles, quickslot wheels, skill bars, companions, units, currencies, skills, buffs). Read-only — not a product addon.

## Install

Install into `AddOns/LibApiCompose/` (release ZIP from GitHub, or `task install:live` from a checkout). Enable in the in-game AddOns list. Not yet listed on ESOUI / Minion.

## Depend on it

```txt
## DependsOn: LibApiCompose>=10000
```

`10000` is `AddOnVersion` for semver `1.0.0` (`major*10000+minor*100+patch`).

```lua
local LAC = LibApiCompose

-- Thin safe call (no compose required)
local level = LAC.SafeCall(GetUnitLevel, "player")

-- Compose → decide → act with raw handles on the record.
-- isLocked covers both the player's lock and a transient slot lock (trade, mail, in use).
local slot = LAC.BagSlot.Compose(BAG_BACKPACK, i)
if slot and not slot.isLocked then
    -- UseItem(slot.bagId, slot.slotIndex)  -- in product code, with CallSecureProtected as needed
end

-- Walk a bag (0-based slots; craft bag supported). Return true to stop early.
LAC.BagSlot.ForBag(BAG_BACKPACK, function(rec)
    if rec.isGear and not rec.isBound then
        -- ...
    end
end)

-- No bag slot? Compose from a link (loot, mail, guild store, chat).
local gear = LAC.Gear.ComposeFromLink(itemLink)

-- Other domains follow the same shape.
local me = LAC.Unit.Compose("player")
local gold = LAC.Currency.Compose(CURT_MONEY)
local bar = LAC.Hotbar.ComposeBar()
local buffs = LAC.Buff.ComposeAll("player")

-- Feature detection across library versions
if LAC.AtLeast(10100) then
    -- use an API added in 1.1.0
end
```

Records are always fresh tables you own. Collectible static facts are memoised; unlocked/active state is
read live, and category lists are invalidated by the library's own collection events.

After a game patch, `/script d(LibApiCompose.SelfTest())` lists any game API the library reads that no longer
exists.

## Versioning

| Field | Scheme |
|-------|--------|
| `## Version:` | Semver (e.g. `1.0.0`) |
| `## AddOnVersion:` | Encoded integer (`1.0.0` → `10000`) |

## Docs

**Developer documentation: <https://solaegis.github.io/lib-api-compose/>** — installation, guides, recipes and
the full API reference. Source in [`docs/`](docs/); preview locally with `task docs:serve`.

- [Architecture](docs/ARCHITECTURE.md)
- [Architecture decisions (ADRs)](docs/ARCHITECTURE_DECISIONS.md)
- [Enrichment styles](docs/ENRICHMENT_STYLES.md)
- [Development](docs/DEVELOPMENT.md)
- [Publishing](docs/PUBLISHING.md)

## Tooling

```bash
task test          # unit + lint + format + validate + ZOS API drift check
task install:live  # copy into Live AddOns
task build         # release ZIP
```
