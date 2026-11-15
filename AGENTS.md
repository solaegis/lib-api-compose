# Agent notes — LibApiCompose

## Learned User Preferences

- After library code changes, run `task install:live` then `/reloadui` for in-game testing (libraries are meant to be installed).
- Prefer `LAC.SafeCall` / `SafeCallMulti` over product-local copies or raw `pcall` in this repo.
- Read-only surface only — no Use*/Set*/Request* wrappers.
- Compose records must retain raw handles; no Decompose API.
- Document architectural changes in `docs/ARCHITECTURE_DECISIONS.md` (amend ADRs).
- Prefer `.yaml` for new YAML files.

## Learned Workspace Facts

- Product: **LibApiCompose** (`LAC`) — solaegis ESO compose/enrich + SafeCall library; GitHub `solaegis/lib-api-compose`.
- PC manifest `LibApiCompose.txt`; `## IsLibrary: true`; ZIP root `LibApiCompose/`.
- Version: semver `## Version:`; encoded `## AddOnVersion:` (`1.0.0` → `10000`).
- OptionalDependsOn: LibDebugLogger only. No SavedVariables. No LAM. No LibStub.
- Consumers: `## DependsOn: LibApiCompose>=10000`.
- Unit tests: `tests/run.lua` via `task test:unit` (modules from the manifest, suites auto-discovered).
- ZOS API drift: `task dev:validate:zos` checks `.luacheckrc` symbols and mock arity against ESOUIDocumentation.txt; `task dev:zos:write` regenerates `src/Symbols.lua`.
- SoT decisions: `docs/ARCHITECTURE_DECISIONS.md`.
