# Development — LibApiCompose

## Setup

```bash
task init          # optional deps hints + pre-commit
task test          # unit + lint + validate
task install:live  # copy into ESO Live AddOns (libraries are meant to be installed)
```

In-game: enable **LibApiCompose**, `/reloadui`.

Prefer `install:live` over symlink on Mac.

## Commands

| Task | Description |
|------|-------------|
| `task test:unit` | Plain Lua mocks |
| `task lint` | Luacheck |
| `task format` | StyLua |
| `task validate` | Manifest / syntax |
| `task build` | Release ZIP |
| `task install:live` | Install to Live |

## Consumer usage

```txt
## DependsOn: LibApiCompose>=10000
```

```lua
local LAC = LibApiCompose
local rec = LAC.BagSlot.Compose(BAG_BACKPACK, slotIndex)
if rec then
    -- decide...
    -- act with rec.bagId, rec.slotIndex, rec.link
end

local level = LAC.SafeCall(GetUnitLevel, "player")
```

## Docs

- [ARCHITECTURE.md](ARCHITECTURE.md)
- [ARCHITECTURE_DECISIONS.md](ARCHITECTURE_DECISIONS.md)
- [ENRICHMENT_STYLES.md](ENRICHMENT_STYLES.md)
- [VERSION_PLACEHOLDER_SYSTEM.md](VERSION_PLACEHOLDER_SYSTEM.md)
- [PUBLISHING.md](PUBLISHING.md)
