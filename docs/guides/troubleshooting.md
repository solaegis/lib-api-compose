# Troubleshooting

## My addon does not load

**Symptom:** your addon shows as "dependency missing" or doesn't appear to run.

1. Is LibApiCompose installed as its own folder, `AddOns/LibApiCompose/LibApiCompose.txt`? A nested folder
   (`AddOns/LibApiCompose/LibApiCompose/…`) from a bad unzip won't load.
2. Is it enabled in the Add-Ons menu (and is "Allow out of date add-ons" ticked after a game patch)?
3. Is the installed version high enough? Run `/script d(LibApiCompose.ADDON_VERSION)` and compare with your
   `## DependsOn: LibApiCompose>=N`.
4. Is there an embedded copy in some other addon's `libs/` folder? Remove it — it can shadow the real one.

## `LibApiCompose` is nil in my code

- Your manifest is missing `## DependsOn: LibApiCompose…`, so ESO may load your files first.
- You wrote `LAC.Something` without `local LAC = LibApiCompose` in that file. There is no global `LAC`.

## A field is always `nil`

- The ZOS API behind it doesn't exist on this client (renamed in a patch, or not added yet). LAC soft-fails
  instead of erroring. Check the field's ZOS source in the [API reference](../reference/index.md) and test with
  `/script d(GetTheFunction ~= nil)`.
- The field needs an option: `name` only appears with `{ includeName = true }`.
- The record type doesn't have it: `set` is filled only for gear (`isGear == true`).

## A collectible list is out of date

Unlocked and active state is read live. Unlocked-by-category lists are cached and cleared by collection
events. If a list is still stale (for example a client where none of those events fire), call
`LibApiCompose.Collectible.InvalidateLists()` or `LibApiCompose.ClearCache()`.

## Bag walk misses slot 0 or the craft bag

Use `LAC.BagSlot.ForBag` instead of your own loop. Bag slots are 0-based, and the craft bag has no size — its
slot index is the item id.

## A SafeCall returns nil and I don't know why

Install LibDebugLogger and open its viewer: each distinct failed call is logged once under `LibApiCompose`.
For a traceback, run `/script LibApiCompose.SetDebug(true)` and trigger the call again.
Or use the multi-return form to see the error:

```lua
local LAC = LibApiCompose
local ok, err = LAC.SafeCallMulti(GetItemLink, BAG_BACKPACK, 0)
if not ok then
    d(err)
end
```

`"SafeCallMulti: function is nil or not a function"` means the API doesn't exist on this client (or you
misspelled it).

## Names show `^n` / `^F` suffixes

You fetched a name yourself. Pass it through `LAC.FormatName(name)`. Names on LAC records are already
formatted.

## Two addons disagree about the library version

ESO loads one copy: the highest `AddOnVersion` installed. Check for stray copies in other addons' folders and
remove them.

## Still stuck

Open an issue at [github.com/solaegis/lib-api-compose/issues](https://github.com/solaegis/lib-api-compose/issues)
with your client API version (`/script d(GetAPIVersion())`), `LibApiCompose.VERSION`, and the LibDebugLogger
output.
