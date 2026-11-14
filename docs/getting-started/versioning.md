# Versioning

LibApiCompose has two version numbers, both driven by one git tag.

| Field | Where | Format | Example |
|---|---|---|---|
| `## Version:` / `LAC.VERSION` | manifest, runtime | semver string | `"1.2.3"` |
| `## AddOnVersion:` / `LAC.ADDON_VERSION` | manifest, runtime | `major*10000 + minor*100 + patch` | `10203` |

| Semver | AddOnVersion |
|---|---|
| 1.0.0 | 10000 |
| 1.1.0 | 10100 |
| 1.2.3 | 10203 |
| 2.0.0 | 20000 |

Minor and patch never exceed 99, so the encoding never collides.

## Requiring a minimum version

Use the encoded number in your manifest:

```text
## DependsOn: LibApiCompose>=10100
```

ESO refuses to load your addon if an older LAC is installed, and tells the user why.

## Feature detection at runtime

When an API is nice-to-have rather than required, check at runtime instead of raising your `DependsOn`:

```lua
local LAC = LibApiCompose

if LAC.AtLeast(10100) then
    -- safe to use something added in 1.1.0
end
```

Prefer `LAC.AtLeast` over comparing `LAC.VERSION` strings — string comparison gets `"1.10.0" < "1.9.0"` wrong.

## What a version bump promises

| Bump | Meaning for you |
|---|---|
| Patch (`1.0.x`) | Bug fixes. No API or field changes. |
| Minor (`1.x.0`) | New functions, new record fields, new `opts`. Nothing removed or renamed. |
| Major (`x.0.0`) | Something was removed, renamed, or changed meaning. Read the [changelog](../changelog.md). |

Details, including what counts as public, are in the [stability policy](../reference/stability.md).
