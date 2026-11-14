# Version placeholder system (library)

| Placeholder | Where | Becomes |
|-------------|-------|---------|
| `@project-version@` | `## Version:`, `LAC.VERSION` in Core.lua, README_ESOUI | Semver from git tag (e.g. `1.0.0`) |
| `@addon-build-version@` | `## AddOnVersion:` | Encoded integer via `set-addon-version.sh` |

## Encoding

`AddOnVersion = major * 10000 + minor * 100 + patch`

| Semver | AddOnVersion |
|--------|--------------|
| 1.0.0 | 10000 |
| 1.2.3 | 10203 |
| 2.0.0 | 20000 |

Non-semver (dev / SHA) → `1` (floor so ZIP validation and DependsOn still work).

```bash
./scripts/replace-version.sh build/LibApiCompose 1.0.0
./scripts/set-addon-version.sh build/LibApiCompose/LibApiCompose.txt 1.0.0
```

Consumers: `## DependsOn: LibApiCompose>=10000`

See ADR-002 in [ARCHITECTURE_DECISIONS.md](ARCHITECTURE_DECISIONS.md).
