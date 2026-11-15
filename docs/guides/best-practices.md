# Best practices

## Depend on it properly

- Declare `## DependsOn: LibApiCompose>=N` with the lowest version whose APIs you call.
- Never embed the library or load its files from your manifest.
- Use `LAC.AtLeast(n)` for optional features instead of raising `DependsOn` for everything.

## Compose at the right time

- **Compose on events, not per frame.** A `BagSlot.Compose` is ~15 ZOS calls. Do it in
  `EVENT_INVENTORY_SINGLE_SLOT_UPDATE`, when a window opens, or on a slash command — never in `OnUpdate`.
- **Compose once per decision.** Build the record, run all your rules against it, then act.
- **Use the narrowest call.** `BagSlot.Compose` is cheaper than `Gear.ComposeFromSlot`; only use Gear when you
  need set, trait or enchant facts. Gear already skips those lookups for non-gear items.
- **Don't keep records around as live state.** They are snapshots. Re-compose after the game tells you
  something changed.

## Act in your addon

- LAC is read-only by design. Keep `UseItem`, `SetItemIsJunk`, `SelectSlotSimpleAction`, `UseCollectible`
  and anything protected in your addon, with your own combat checks and `CallSecureProtected` where needed.
- Act with the record's identity fields, not by re-deriving them: `UseItem(rec.bagId, rec.slotIndex)`.
- Re-check volatile conditions right before a write if time has passed since you composed
  (the item may have moved).

## Keys and storage

- Store items in SavedVariables by `rec.uniqueIdString`. Bag positions change; unique ids don't.
- Key in-memory maps by `LAC.SlotKey(bagId, slotIndex)` or `LAC.HotbarSlotKey(category, slot)` — one
  number, no string building, safe for the craft bag.
- Never store a `uniqueId` (id64 userdata) in SavedVariables; use the string.

## Localisation

- Display names come back through `LAC.FormatName`, which strips ZOS grammar suffixes (`"Bear^n"` → `"Bear"`).
  Use it for any name you fetch yourself.
- Compare names case-insensitively with `LAC.LowerName`, which uses `zo_strlower` so German and French
  characters lower correctly. `string.lower` doesn't handle UTF-8.
- Never match on display names when an id exists. `Collectible.FindByName` is for user-typed input only.

## Defensive reading

- Guard records: `if not rec then return end`.
- Treat non-boolean fields as optional; a field can be `nil` on a client where its API doesn't exist.
- Boolean flags (`isLocked`, `unlocked`, `usable`) are always `true` or `false`.
- Check `rec.isEmpty` on quickslot records before using `actionId`.

## Errors and debugging

- Install LibDebugLogger while developing; LAC logs each distinct failed ZOS call once (`LAC.SetDebug(true)` adds
  tracebacks).
- Use `LAC.SafeCallMulti` when you need to know *why* a call failed (`ok, err`).
- Don't wrap your own functions in `SafeCall` to hide bugs.

## Performance

| Operation | Approximate ZOS calls |
|---|---|
| `BagSlot.Compose` | 15 |
| `Gear.ComposeFromSlot` (gear item) | 20 |
| `Collectible.Compose` (cached static facts) | 3 |
| `Quickslot.Compose` (non-empty) | 6 |
| `Quickslot.ComposeWheel` | ≤ 48 |
| `BagSlot.ForBag(BAG_BANK)` (480 occupied slots) | ~7,000 |

ESO API calls are synchronous and fast, but thousands in one frame cause a visible hitch. For big walks:

- filter early (check `slot.isGear` before composing Gear);
- spread work across frames with your own pacing (`zo_callLater` or LibAsync) — LAC deliberately doesn't
  (ADR-007);
- cache results in your addon and refresh on inventory events.
