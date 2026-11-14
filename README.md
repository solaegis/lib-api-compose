# LibApiCompose

[![Version](https://img.shields.io/github/v/release/solaegis/lib-api-compose?include_prereleases&sort=semver&label=Version)](https://github.com/solaegis/lib-api-compose/releases)
[![ESO API](https://img.shields.io/badge/ESO_API-101051-blue)](https://github.com/solaegis/lib-api-compose)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)

solaegis ESO **library**: canonical `SafeCall` / `SafeCallMulti`, index walkers, and shared compose/enrich helpers (bag, gear, collectibles, quickslots, OnUse links, companions). Read-only — not a product addon.

## Install

Install into `AddOns/LibApiCompose/` (Minion / MacMinion / `task install:live`). Enable in the in-game AddOns list.

## Depend on it

```txt
## DependsOn: LibApiCompose>=10000
```

`10000` is `AddOnVersion` for semver `1.0.0` (`major*10000+minor*100+patch`).

```lua
local LAC = LibApiCompose

-- Thin safe call (no compose required)
local level = LAC.SafeCall(GetUnitLevel, "player")

-- Compose → decide → act with raw handles on the record
local slot = LAC.BagSlot.Compose(BAG_BACKPACK, i)
if slot then
    -- UseItem(slot.bagId, slot.slotIndex)  -- in product code, with CallSecureProtected as needed
end
```

## Versioning

| Field | Scheme |
|-------|--------|
| `## Version:` | Semver (e.g. `1.0.0`) |
| `## AddOnVersion:` | Encoded integer (`1.0.0` → `10000`) |

## Docs

- [Architecture](docs/ARCHITECTURE.md)
- [Architecture decisions (ADRs)](docs/ARCHITECTURE_DECISIONS.md)
- [Enrichment styles](docs/ENRICHMENT_STYLES.md)
- [Development](docs/DEVELOPMENT.md)
- [Publishing](docs/PUBLISHING.md)

## Tooling

```bash
task test          # unit + lint + validate
task install:live  # copy into Live AddOns
task build         # release ZIP
```
