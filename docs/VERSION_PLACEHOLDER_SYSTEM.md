# Version placeholder system (library)

| Placeholder | Where | Becomes |
|-------------|-------|---------|
| `@project-version@` | `## Version:`, `LAC.VERSION` in Core.lua, README_ESOUI | Semver from git tag (e.g. `1.0.0`) |
| _(integer, committed)_ | `## AddOnVersion:`, `LAC.ADDON_VERSION` in Core.lua | Encoded integer via `set-addon-version.sh` |

The source manifest commits a real integer (the current release's encoding, e.g. `10000`) rather than a
placeholder, so symlink dev installs (`task install:dev`) satisfy `DependsOn: LibApiCompose>=N`.

## Encoding

`AddOnVersion = major * 10000 + minor * 100 + patch`

| Semver | AddOnVersion |
|--------|--------------|
| 1.0.0 | 10000 |
| 1.2.3 | 10203 |
| 2.0.0 | 20000 |

Minor and patch must be `< 100`; the script fails the build otherwise (`1.100.0` would collide with `2.0.0`).

Non-semver (dev / SHA) → keeps the committed integer (falls back to `1` if none), so dev installs still satisfy DependsOn.

```bash
./scripts/replace-version.sh build/LibApiCompose 1.0.0
./scripts/set-addon-version.sh build/LibApiCompose/LibApiCompose.txt 1.0.0
```

Consumers: `## DependsOn: LibApiCompose>=10000`

See ADR-002 in [ARCHITECTURE_DECISIONS.md](ARCHITECTURE_DECISIONS.md).
