# Architecture decisions — LibApiCompose

Durable record of design choices. Status / Context / Decision / Consequences.
Amend in-repo when overturned; do not leave rationale only in chat.

Bootstrap date: 2026-11-14.

---

## ADR-001 — Library identity

**Status:** Accepted

**Context:** solaegis needs a shared compose/SafeCall library for ESO addons. ESOUI requires `IsLibrary: true` and a standalone manifest.

**Decision:** Folder/manifest/global `LibApiCompose`, alias `LAC`, GitHub `solaegis/lib-api-compose`. Standalone install only; never embed under `/libs`.

**Consequences:** Consumers use `## DependsOn: LibApiCompose>=N`. Game loads highest AddOnVersion.

---

## ADR-002 — Versioning

**Status:** Accepted

**Context:** Product addons use semver for `## Version:` and often YYYYMMDD for `## AddOnVersion:`. Libraries need integer AddOnVersion for `DependsOn>=` and game precedence. LibStub is obsolete.

**Decision:** `## Version:` = semver from git tag (`@project-version@`). `## AddOnVersion:` = `major*10000 + minor*100 + patch` (e.g. `1.2.3` → `10203`). Script: `scripts/set-addon-version.sh`.

**Consequences:** One tag drives both fields. Non-semver builds encode as `0`. First release `v1.0.0` → `10000`.

---

## ADR-003 — Canonical SafeCall

**Status:** Accepted

**Context:** Every solaegis product reimplemented SafeCall; reviews still miss raw `pcall` on multi-return APIs.

**Decision:** `LAC.SafeCall` / `LAC.SafeCallMulti` (CM/EAP semantics, nil-hole preserving) are the only ZOS call path inside this lib. Thin passthroughs use them without compose. Callers choose SafeCall vs SafeCallMulti from API arity (not a magic overload).

**Consequences:** Products may later alias their SafeCall to LAC. Domain files must not use raw `pcall`.

---

## ADR-004 — Enrichment styles

**Status:** Accepted

**Context:** CharacterMarkdown `src/api` and solaegis products use several enrichment patterns (index, nested, id, bag, hotbar, unit, aggregate, policy).

**Decision:** Lib provides primitives for styles A–G. Style H (product policy / FSM) stays in products.

**Consequences:** No full ZOS catalog. No generic `Enrich("domain", i)` registry in v1.

---

## ADR-005 — v1 shared domains

**Status:** Accepted

**Context:** Cross-repo ROI favors bag/gear, collectibles, quickslots, OnUse links, companions.

**Decision:** Ship BagSlot, Gear, Collectible, Quickslot, ItemLink.OnUse, Companion. Defer CM-heavy skills/armory/world/crafting/appearance/PvP until a second consumer needs them.

**Consequences:** ECL may be the only Quickslot consumer initially; still ship it.

---

## ADR-006 — Eager load; lazy data only

**Status:** Accepted

**Context:** ESO has no `require` / dynamic Lua load. All manifest files parse at addon load.

**Decision:** Keep modules lean and list them all in the manifest. Expensive aggregates use first-use memo caches + `ClearCache`, not lazy file load.

**Consequences:** Load cost is proportional to code size, not to first Compose call (except cached walks).

---

## ADR-007 — Performance model

**Status:** Accepted

**Context:** Single-threaded frame-bound Lua; no parallelization; ZOS Get* are sync; LibAsync spreads work across frames.

**Decision:** Compose APIs are sync and cheap. No LibAsync DependsOn. No cache TTL. Products own pacing/chunking. Do not re-Compose every HUD frame.

**Consequences:** Huge catalog walks are consumer-driven or sync+cache once.

---

## ADR-008 — Systems contracts

**Status:** Accepted

**Context:** Shared libs can leak events, mutate caches across addons, or wrap combat-locked writes unsafely.

**Decision:** Read/query only (no Use*/Set*/Request*). Fresh return tables / copied lists. No SavedVariables. No lib EVENT_MANAGER / CALLBACK bus. Soft-fail missing ZOS symbols via SafeCall. Optional LibDebugLogger only. Zero required DependsOn.

**Consequences:** Consumers call `ClearCache` after their own inventory/collectible events.

---

## ADR-009 — Data structures

**Status:** Accepted

**Context:** Need readable records, reliable lists, and fast keys without clever Lua.

**Decision:** Named compose records + nested sub-records; `opts?` tables; `nil` = miss; `LAC.NONE` sentinel for explicit none in lists; `{ list, count, total? }`; SlotKey / HotbarSlotKey; ForLinked. No metatable freeze, weak tables, Result monads, or OOP classes.

**Consequences:** Field contracts are semver-stable; document in README / Compose headers.

---

## ADR-010 — No Decompose; retain raw handles

**Status:** Accepted

**Context:** Developers need bag/slot/id/link for write and follow-up APIs after enriching.

**Decision:** No `Decompose*` family. Every compose record keeps identity fields. Optional `Args` helpers only.

**Consequences:** Compose for decide; fields for act. No fake inverse from link→slot.

---

## ADR-011 — Optional LibDebugLogger

**Status:** Accepted

**Context:** Debug without chat spam or hard dependency.

**Decision:** `## OptionalDependsOn: LibDebugLogger`. SafeCall failures debug-log only when present.

**Consequences:** Silent by default for end users.

---

## ADR-012 — Testing

**Status:** Accepted

**Context:** ESO APIs unavailable in CI.

**Decision:** Plain Lua mock harness under `tests/` (`task test:unit` / `tests/run.lua`) covering SafeCall, Iterate, BagSlot/Gear, ItemLink.

**Consequences:** Green CI is necessary but not sufficient; install:live for in-game checks.
