# CLAUDE.md

Guidance for Claude Code when working in this repository.

## Overview

LibApiCompose is a solaegis ESO PC **library**: SafeCall/SafeCallMulti, iterate helpers, and compose/enrich domains (ItemLink, BagSlot, Gear, Collectible, Quickslot, Hotbar, Companion, Unit, Currency, Skill, Buff). ESO Lua 5.1; no `goto`. `IsLibrary: true`.

## Build & Development Commands

- **Lint**: `task lint`
- **Test**: `task test` / `task test:unit`
- **Validate**: `task validate`
- **Build**: `task build` / `task build:fast`
- **Install to ESO Live**: `task install:live`

## Architecture

Load order: Core → Iterate → ItemLink → BagSlot → Gear → Collectible → Quickslot → Hotbar → Companion → Unit → Currency → Skill → Buff → Symbols (generated).

See `docs/ARCHITECTURE.md` and `docs/ARCHITECTURE_DECISIONS.md`. Developer docs site: `docs/` (MkDocs, `mkdocs.yml`), published to GitHub Pages.

## Code Conventions

- Lua 5.1 only (no `goto`)
- All ZOS calls via `LAC.SafeCall` / `SafeCallMulti`
- Fresh compose records; copy cached lists; `ClearCache` public
- After code changes: `task install:live`
- New ZOS globals go in the sorted `BEGIN ZOS API` block of `.luacheckrc`, then `task dev:zos:write`; `task test` checks them (and mock arity) against ESOUIDocumentation.txt
- Empty strings from ZOS → `nil` via `LAC.NonEmpty`
- Public API changes need a reference heading (### `Module.Function`) in `docs/reference/`; `task docs:build` checks it
