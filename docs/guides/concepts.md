# Core concepts

## Compose → decide → act

```text
raw handles  →  LAC.*.Compose(...)  →  decide in your addon  →  identity fields on the record  →  ZOS write APIs
```

1. **Compose.** Turn a handle (bag + slot, collectible id, hotbar slot, item link) into a record with one call.
   Every ZOS call inside goes through `SafeCall`, so composing never throws.
2. **Decide.** Your addon's rules read plain fields: `rec.isLocked`, `rec.set.count`, `rec.unlocked`.
3. **Act.** Call ZOS yourself with the identity fields the record kept: `UseItem(rec.bagId, rec.slotIndex)`,
   `UseCollectible(rec.id)`.

There is no `Decompose` and no write wrapper. Protected calls, combat lockdown and user intent are your addon's
business (ADR-008, ADR-010).

## Records

A record is a plain Lua table with named fields. Nested facts live in sub-tables (`gear.set.name`,
`gear.enchant.hasCharges`).

### Identity fields vs facts

| Kind | Purpose | Examples |
|---|---|---|
| Identity | Pass back into ZOS to act | `bagId`, `slotIndex`, `id`, `link`, `uniqueId`, `hotbarCategory`, `actionType`, `actionId` |
| Facts | Read to decide | `isLocked`, `functionalQuality`, `set.count`, `unlocked`, `cooldown` |

Every record keeps its identity fields, even when you only asked for facts.

### Records are fresh and yours

Every call returns **new tables**. Mutate them, store them, add your own fields — nothing inside LAC or any other
addon sees the change. This holds for cached domains too: the cache stores facts, never the table you got.

```lua
local LAC = LibApiCompose

local rec = LAC.Collectible.Compose(5)
rec.myScore = 10           -- fine: your table
rec.name = "renamed"       -- fine: doesn't affect the next Compose
```

### `nil` means "missing"

| Situation | Result |
|---|---|
| Handle is empty or invalid (empty slot, id `0`, empty link) | the Compose returns `nil` |
| A single fact can't be read (API missing on this client, call errored) | that field is `nil` |
| A boolean fact can't be read | `false` (flags are normalised with `== true`) |

Always guard the record (`if rec then`) and treat optional fields as optional. Quickslot is the exception: it
always returns a record and sets `isEmpty`, because empty wheel slots are meaningful in a UI.

### `opts`

Compose functions take an optional `opts` table last. Unknown keys are ignored, and new options only ever add
work, so `nil` always gives the cheapest default.

```lua
local LAC = LibApiCompose
local named = LAC.BagSlot.Compose(BAG_BACKPACK, 3, { includeName = true })
```

### Lists

Aggregates return `{ list = {...}, count = n, total = m }`:

- `list` — array of fresh records.
- `count` — `#list`.
- `total` — how many things were examined (for example every collectible in a category, unlocked or not).

`LAC.NONE` (`"LAC_NONE"`) is a sentinel you can put in your own lists where `nil` would leave a hole
(`nil` inside a table constructor shortens `#t`).

## Soft failure

LAC is written for a game whose API changes every few months. Every ZOS call goes through
[`SafeCall`](safecall.md), so:

- a function that doesn't exist on the running client returns `nil` instead of erroring;
- a function that errors returns `nil` (and logs to LibDebugLogger if installed);
- the rest of the record is still filled in.

You get partial data instead of a broken addon. Check the fields you depend on.

## Enrichment styles

LAC sorts ZOS access patterns into styles A–H (flat index, nested index, id lookup, bag slot, hotbar, unit,
aggregate, product policy) and gives you primitives for A–G. Style H — your addon's rules — stays in your addon.
See [Enrichment styles](../ENRICHMENT_STYLES.md).
