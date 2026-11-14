# Installation

## For players

LibApiCompose is a standalone library. Install it once and every addon that depends on it shares it.

- **Minion:** search for *LibApiCompose* and install.
- **Manual:** unzip so the folder is `Documents/Elder Scrolls Online/live/AddOns/LibApiCompose/`
  (the folder must contain `LibApiCompose.txt`). Then enable it in the in-game **Add-Ons** menu.

## For addon authors

### 1. Declare the dependency

In your addon's manifest (`MyAddon.txt`):

```text
## DependsOn: LibApiCompose>=10000
```

`10000` is the encoded `AddOnVersion` for `1.0.0` (`major*10000 + minor*100 + patch`). Raise it to the lowest
version that has every API you call — see [Versioning](versioning.md).

ESO resolves the dependency before loading your addon, so `LibApiCompose` exists by the time your files run.

!!! warning "Never embed the library"
    Do not copy LibApiCompose into your addon's `libs/` folder or list its files in your manifest. ESO loads
    the highest installed `AddOnVersion` of a standalone library; an embedded copy can shadow a newer one and
    breaks the shared caches. Tell users to install it alongside your addon.

### 2. Alias it

```lua
local LAC = LibApiCompose
```

Keep the alias `local` at the top of each file. There is no global `LAC`.

### 3. Optional: LibDebugLogger

If [LibDebugLogger](https://www.esoui.com/downloads/info2275-LibDebugLogger.html) is installed, LAC logs every
failed `SafeCall` with a traceback under the `LibApiCompose` tag. You don't need to declare it; LAC lists it as
`## OptionalDependsOn`.

## Checking it loaded

In chat:

```text
/script d(LibApiCompose.VERSION, LibApiCompose.ADDON_VERSION)
```

Expected output is the semver string (for example `1.0.0`) and the encoded integer (`10000`). If you get
`nil`, the library isn't enabled — see [Troubleshooting](../guides/troubleshooting.md#my-addon-does-not-load).
