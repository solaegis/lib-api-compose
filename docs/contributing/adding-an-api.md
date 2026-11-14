# Adding an API

Checklist for a new function, record field or module. Copy it into your PR description.

## Design

- [ ] Fits an [enrichment style](../ENRICHMENT_STYLES.md) A–G. Product policy (style H) stays out.
- [ ] Read-only: no `Use*`, `Set*`, `Request*`, protected calls or SavedVariables.
- [ ] Has, or will soon have, at least one consumer addon (ADR-005: no speculative domains).
- [ ] Name follows the module's verbs: `Compose…` returns a record, `For…` walks with a callback,
      `Map…` collects, `…Args` unpacks identity.
- [ ] New field names are descriptive and typed consistently (`is…`/`has…`/`can…` for booleans).

## Implementation

- [ ] Every ZOS call goes through `LAC.SafeCall` or `LAC.SafeCallMulti` (multi-return APIs use Multi).
- [ ] Old/new API pairs branch on existence (`if GetNew then … else GetOld`), never on version numbers.
- [ ] The record keeps every identity field needed to act on it.
- [ ] Returns a fresh table; nothing returned is also stored in a cache.
- [ ] Booleans normalised with `== true`; display names through `LAC.FormatName`.
- [ ] `opts` keys default to the cheapest behaviour.
- [ ] Shared helpers go on `LAC._internal`, not on the public module table.
- [ ] New module? Add it to `LibApiCompose.txt` in dependency order and to `tests/run.lua`.
- [ ] Every new ZOS global is listed in `.luacheckrc` `read_globals`.

## Tests

- [ ] Mock stubs for new ZOS APIs return the real shape, with the signature in a comment
      ([Testing](testing.md#mocks-must-match-the-real-return-shape)).
- [ ] Cases for: normal record, empty/invalid handle, missing API, and any cache behaviour.
- [ ] `task test` passes.

## Documentation

- [ ] Reference entry under a `` ### `Module.Function` `` heading on the module page, using the standard
      template (signature, parameters, returns, example, *Since x.y.z*). `task docs:check` fails without it.
- [ ] New record fields added to the module's **Record** table and to [Record schemas](../reference/records.md).
- [ ] Function added to the [reference index](../reference/index.md) table.
- [ ] Guide or recipe updated if it changes how people should use the library.
- [ ] `CHANGELOG.md` entry under `[Unreleased]`.
- [ ] ADR added or amended if a contract changed.
- [ ] `task docs:build` passes.

## Release impact

| Change | Version bump |
|---|---|
| New function, field, `opts` key | minor |
| Fix wrong data | patch |
| Remove/rename/change meaning | major (deprecate first — see [Stability](../reference/stability.md#deprecation)) |
