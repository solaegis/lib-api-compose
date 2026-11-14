# Iterate

`src/Iterate.lua` — walkers for ZOS collection shapes. Available as `LAC.Iterate.*` and as aliases on `LAC`
(`LAC.ForIndex`, `LAC.MapIndex`, `LAC.NestedFor`, `LAC.NestedMap`, `LAC.ForLinked`).

Counts and lookups go through `SafeCall`; your callbacks are **not** protected. See the
[Iteration guide](../guides/iteration.md).

## Functions

### `Iterate.ForIndex`

```text
Iterate.ForIndex(getNum, getAt?, fn, needMulti?)
```

Calls `fn` for `i = 1 .. getNum()`.

| Parameter | Type | Description |
|---|---|---|
| `getNum` | `function` | Called with no arguments; returns the count. Error or `nil` → `0`. |
| `getAt` | `function?` | Called as `getAt(i)`. When `nil`, `fn` receives only `i`. |
| `fn` | `function` | `fn(i, ...)`. When `nil`, nothing happens. |
| `needMulti` | `boolean?` | `true`: forward up to 8 return values of `getAt` and skip indices where `getAt` errors. Otherwise forward the first value (`nil` on error). |

**Returns:** nothing.

*Since 1.0.0.*

### `Iterate.MapIndex`

```text
Iterate.MapIndex(getNum, getAt?, mapFn, needMulti?) -> table
```

Like `ForIndex`, collecting non-`nil` results of `mapFn(i, ...)` into an array.

**Returns:** array of results (may be empty).

```lua
local LAC = LibApiCompose
local tens = LAC.MapIndex(function()
    return 3
end, function(i)
    return i * 10
end, function(_, value)
    return value
end)
-- tens == { 10, 20, 30 }
```

*Since 1.0.0.*

### `Iterate.NestedFor`

```text
Iterate.NestedFor(levels, fn)
```

Walks every combination of nested indices and calls `fn(i1, i2, …, iN)` at the deepest level.

| Parameter | Type | Description |
|---|---|---|
| `levels` | `table` | Array of `{ getNum = function(parentIndices...) }`. Level 1's `getNum` gets no arguments, level 2's gets `i1`, and so on. |
| `fn` | `function` | Leaf callback receiving all indices. |

Empty `levels`, or a level without `getNum`, walks nothing.

*Since 1.0.0.*

### `Iterate.NestedMap`

```text
Iterate.NestedMap(levels, mapFn) -> table
```

Like `NestedFor`, collecting non-`nil` results of `mapFn(i1, …, iN)`.

*Since 1.0.0.*

### `Iterate.ForLinked`

```text
Iterate.ForLinked(getNext, mapFn?, maxSteps?) -> table
```

Follows a chain of ids: `getNext(nil)` is the first id, `getNext(id)` the next, `nil` ends.

| Parameter | Type | Description |
|---|---|---|
| `getNext` | `function` | Id iterator, e.g. `GetNextVirtualBagSlotId`. |
| `mapFn` | `function?` | `mapFn(id)`; non-`nil` results are collected. When `nil`, the ids themselves are collected. |
| `maxSteps` | `integer?` | Upper bound on steps. Default `Iterate.MAX_LINKED_STEPS`. Hitting it is logged. |

**Returns:** array of results or ids.

*Since 1.0.0.*

## Constants

| Name | Value | Meaning |
|---|---|---|
| `Iterate.MAX_LINKED_STEPS` | `100000` | Default `ForLinked` and craft-bag step limit |
