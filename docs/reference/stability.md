# Stability policy

LibApiCompose follows [semantic versioning](https://semver.org/). This page defines what "the API" is, so you
know what a version bump can change.

## Public

Covered by semver:

- Every function and constant documented in this reference.
- Every documented record field: its name, type and meaning.
- Every documented `opts` key and its default.
- Return shapes: when a function returns `nil` vs a record, and aggregate `{ list, count, total }` shapes.
- The `## DependsOn` encoding (`major*10000 + minor*100 + patch`).

## Not public

May change in any release, including patches:

- `LAC._internal` and any field or function whose name starts with `_` (e.g. `LAC._logger`).
- Undocumented fields that happen to exist on a record.
- Error message text from `SafeCallMulti` (the `false` is stable; the string isn't).
- Which ZOS API a field is read from, as long as the field keeps its meaning.
- Cache timing: when a cached list is rebuilt. Correctness is promised; timing isn't.
- Log output.

## What each bump may do

| Change | Patch | Minor | Major |
|---|---|---|---|
| Fix a field that returned wrong data | ✓ | ✓ | ✓ |
| Add a function, record field, `opts` key or constant | | ✓ | ✓ |
| Fill a field that used to be always `nil` on some client | ✓ | ✓ | ✓ |
| Remove or rename a function, field or `opts` key | | | ✓ |
| Change a field's type or meaning | | | ✓ |
| Change a default (`opts` key absent) | | | ✓ |
| Change when a function returns `nil` | | | ✓ |

## Deprecation

Before a removal in the next major version:

1. The replacement ships in a minor release.
2. The old name keeps working and is marked **Deprecated** in this reference and the changelog.
3. Removal happens only in a major release.

## ZOS API changes

ESO patches rename and remove APIs. When that happens LAC keeps the record field and reads it from the new API,
or falls back between old and new APIs, in a patch release. If the game removes the data entirely, the field
becomes `nil` on that client (soft failure) and the change is noted in the changelog.
