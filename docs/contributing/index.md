# Contributing

Thanks for helping. This section is for people changing the library itself. If you only *use* LAC, start at
[Quick start](../getting-started/quickstart.md).

## Setup

Requirements: [Task](https://taskfile.dev), LuaJIT (or Lua 5.1), [luacheck](https://github.com/lunarmodules/luacheck),
[StyLua](https://github.com/JohnnyMorganz/StyLua), [pre-commit](https://pre-commit.com), Python 3 for the docs site.

```bash
brew install go-task stylua luajit pre-commit
luarocks install luacheck
task init           # pre-commit hooks + dev install
```

## Everyday commands

| Command | What it does |
|---|---|
| `task test` | Unit tests + lint + format check + all validations — run before every commit |
| `task test:unit` | Unit tests only (`tests/run.lua`) |
| `task lint` / `task lint:fix` | Luacheck on `src/`, `tests/`, scripts |
| `task format` | StyLua |
| `task validate` | Manifest, required files, Lua syntax |
| `task build` | Release ZIP in `dist/` (runs tests first) |
| `task build:fast` | ZIP without tests |
| `task install:live` | Copy into the ESO Live AddOns folder with versions stamped |
| `task install:dev` | Symlink the repo into AddOns for `/reloadui` iteration |
| `task docs:serve` | Preview this site at `http://127.0.0.1:8000` |
| `task docs:build` | Strict docs build + API drift check |

## Repository layout

```text
LibApiCompose.txt        manifest (load order lives here)
src/
  Core.lua               SafeCall, keys, names, cache control — loads first
  Iterate.lua            walkers
  BagSlot.lua            bag slot records + bag walkers
  Gear.lua               gear facts on BagSlot
  Collectible.lua        collectible records, caches, invalidation events
  Quickslot.lua          hotbar / wheel records
  ItemLink.lua           on-use preview
  Companion.lua          companion records
tests/
  run.lua                test runner (describe / it / assert*)
  mock/eso.lua           ZOS API stubs
  test_*.lua             suites
docs/                    this site (MkDocs)
scripts/                 build, version and validation scripts
taskfiles/               Task includes
```

## Ground rules

- **Lua 5.1 only.** No `goto`, no integer division, no `table.unpack` (use `unpack`).
- **Every ZOS call goes through `LAC.SafeCall` / `SafeCallMulti`.** No raw `pcall` in domain files (ADR-003).
- **Read-only.** No `Use*`, `Set*`, `Request*`, no protected calls, no SavedVariables (ADR-008).
- **Fresh records.** Never return a table that's also held in a cache.
- **Soft-fail.** A missing ZOS API must leave a field `nil`, never break the record.
- **Docs move with code.** A public change isn't done until the [reference](../reference/index.md) and
  `CHANGELOG.md` say so. `task docs:check` enforces the reference part.

## Workflow

1. Branch from `main`.
2. Make the change, with tests (see [Testing](testing.md)).
3. `task test` and `task docs:build`.
4. Update `CHANGELOG.md` under `[Unreleased]`.
5. If you changed a contract, add or amend an ADR in [Architecture decisions](../ARCHITECTURE_DECISIONS.md).
6. `task install:live`, `/reloadui`, and try it in game.
7. Open a PR.

Adding a new function or module? Follow the checklist in [Adding an API](adding-an-api.md).

## Further reading

- [Architecture](../ARCHITECTURE.md) and [decisions](../ARCHITECTURE_DECISIONS.md)
- [Lua patterns](../LUA_PATTERNS.md)
- [Publishing](../PUBLISHING.md) and [versioning internals](../VERSION_PLACEHOLDER_SYSTEM.md)
- [ESOUI best practices](../esoui-addon-best-practices.md)
