# CLAUDE.md

Guidance for Claude Code when working in this repository.

## Overview

LibApiCompose is a solaegis ESO PC **library**: SafeCall/SafeCallMulti, iterate helpers, and compose/enrich domains (BagSlot, Gear, Collectible, Quickslot, ItemLink, Companion). ESO Lua 5.1; no `goto`. `IsLibrary: true`.

## Build & Development Commands

- **Lint**: `task lint`
- **Test**: `task test` / `task test:unit`
- **Validate**: `task validate`
- **Build**: `task build` / `task build:fast`
- **Install to ESO Live**: `task install:live`

## Architecture

Load order: Core → Iterate → BagSlot → Gear → Collectible → Quickslot → ItemLink → Companion.

See `docs/ARCHITECTURE.md` and `docs/ARCHITECTURE_DECISIONS.md`.

## Code Conventions

- Lua 5.1 only (no `goto`)
- All ZOS calls via `LAC.SafeCall` / `SafeCallMulti`
- Fresh compose records; copy cached lists; `ClearCache` public
- After code changes: `task install:live`
