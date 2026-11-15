# Iterate

`src/Iterate.lua` — walkers for ZOS collection shapes. Available as `LAC.Iterate.*` and as aliases on `LAC`
(`LAC.ForIndex`, `LAC.MapIndex`, `LAC.NestedFor`, `LAC.NestedMap`, `LAC.ForLinked`, `LAC.MapLinked`).

Counts and lookups go through `SafeCall`; your callbacks are **not** protected. Every `For*` walker stops when
its callback returns `true`. See the [Iteration guide](../guides/iteration.md).

## Functions

### `Iterate.ForIndex`

```text
Iterate.ForIndex(getNum, getAt?, fn, needMulti?) -> integer
```

Calls `fn` for `i = 1 .. getNum()`.

| Parameter | Type | Description |
|---|---|---|
| `getNum` | `function` | Called with no arguments; returns the count. Error or `nil` → `0`. |
| `getAt` | `function?` | Called as `getAt(i)`. When `nil`, `fn` receives only `i`. |
| `fn` | `function` | `fn(i, ...)`. Return `true` to stop. When `nil`, nothing happens. |
| `needMulti` | `boolean?` | `true`: forward **every** return value of `getAt` (no limit, `nil`s preserved). Otherwise forward only the first. |

An index where `getAt` raises an error is skipped (`fn` is not called for it), in both modes.

**Returns:** the number of indices walked.

*Since 1.0.0.*

### `Iterate.MapIndex`

```text
Iterate.MapIndex(getNum, getAt?, mapFn, needMulti?) -> table
```

Like `ForIndex`, collecting non-`nil` results of `mapFn(i, ...)` into an array. There is no early exit.

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
| `fn` | `function` | Leaf callback receiving all indices. Return `true` to stop the whole walk. |

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
Iterate.ForLinked(getNext, fn, maxSteps?, zeroIsValid?) -> integer
```

Follows a chain of ids: `getNext(nil)` is the first id, `getNext(id)` the next.

| Parameter | Type | Description |
|---|---|---|
| `getNext` | `function` | Id iterator, e.g. `GetNextVirtualBagSlotId`. |
| `fn` | `function` | `fn(id)`. Return `true` to stop. |
| `maxSteps` | `integer?` | Upper bound on ids visited. Default `Iterate.MAX_LINKED_STEPS`. Hitting it is logged. |
| `zeroIsValid` | `boolean?` | Treat `0` as a real id. Default `false`. |

The chain ends on `nil`, on `0` (many ZOS iterators, e.g. `GetNextAchievementInLine`, end with `0`), or when
`getNext` returns the id it was given.

**Returns:** the number of ids visited.

*Since 1.0.0.*

### `Iterate.MapLinked`

```text
Iterate.MapLinked(getNext, mapFn?, maxSteps?, zeroIsValid?) -> table
```

Like `ForLinked`, collecting non-`nil` results of `mapFn(id)`, or the ids themselves when `mapFn` is `nil`.

```lua
local LAC = LibApiCompose
local craftBagItemIds = LAC.MapLinked(GetNextVirtualBagSlotId)
```

*Since 1.0.0.*

## Constants

| Name | Value | Meaning |
|---|---|---|
| `Iterate.MAX_LINKED_STEPS` | `100000` | Default `ForLinked` and linked-bag step limit |
