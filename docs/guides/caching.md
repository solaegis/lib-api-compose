# Caching

Most of LAC is uncached: bag slots, gear, quickslots, item links and companions are composed fresh on every call,
because that state changes constantly. Only the Collectible module caches, and only data that is either static or
kept correct automatically.

## What is cached

| Data | Cached? | Kept fresh by |
|---|---|---|
| Collectible name, icon, category | Yes, per id | Static for the session; `LAC.ClearCache()` drops it |
| Collectible `unlocked`, `active`, `nickname` | **No** — read live on every `Compose` | — |
| Unlocked ids per category (`ComposeUnlockedByCategory`) | Yes, per category | Collection events (below) or `ClearCache` |
| Name → id index per category (`IndexByName`) | Yes, per category | Collection events or `ClearCache` |
| Everything else | No | — |

Records built from cached data are still fresh tables (see [Core concepts](concepts.md#records-are-fresh-and-yours)).

## Self-invalidation

At load, LAC registers handlers for whichever of these events exist on the client:

- `EVENT_COLLECTION_UPDATED`
- `EVENT_COLLECTIBLES_UNLOCK_STATE_CHANGED`
- `EVENT_COLLECTIBLE_UPDATED`
- `EVENT_COLLECTIBLES_UPDATED`

Each one calls `LAC.Collectible.InvalidateLists()`, which drops the category lists and name indexes. The next
call rebuilds them. Handlers only clear LAC's own caches; LAC never re-broadcasts events or exposes callbacks
(ADR-008).

## Why it works this way

The cache is shared by **every addon** that uses LAC. If correctness depended on each addon calling
`ClearCache` after its own events, one addon that forgot would leave stale data for all of them. So volatile
facts are never cached, and lists clear themselves.

## Forcing a refresh

```lua
local LAC = LibApiCompose

LAC.ClearCache()                     -- drop every LAC cache
LAC.Collectible.InvalidateLists()    -- drop only category lists and name indexes
local fresh = LAC.Collectible.Compose(5, { skipCache = true }) -- bypass the per-id cache once
```

You rarely need these. Reasonable cases: a test harness, a `/reloadui`-free debug command, or working around a
client where none of the collection events fire.

## Your own caches

If you cache LAC records in your addon, you own their freshness. Good keys:

| Thing | Key | Why |
|---|---|---|
| An item, across moves and sessions | `rec.uniqueIdString` | `uniqueId` is an id64 userdata; the string form is safe in SavedVariables |
| An item in a slot, this session | `LAC.SlotKey(rec.bagId, rec.slotIndex)` | one number, works for the craft bag |
| A quickslot | `LAC.HotbarSlotKey(rec.hotbarCategory, rec.slotIndex)` | one number |
| A collectible | `rec.id` | stable |

Invalidate on the matching ZOS events (`EVENT_INVENTORY_SINGLE_SLOT_UPDATE`, `EVENT_ACTION_SLOT_UPDATED`, …).
