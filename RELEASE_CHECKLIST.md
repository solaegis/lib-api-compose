# Release checklist — LibApiCompose

- [ ] `CHANGELOG.md` updated for the version
- [ ] `task test` passes
- [ ] Tag `vX.Y.Z` (semver) — CI encodes AddOnVersion
- [ ] GitHub Release ZIP root is `LibApiCompose/`
- [ ] Consumers documented with `## DependsOn: LibApiCompose>=N`
- [ ] ESOUI upload only when `ESOUI_ADDON_ID != 0`
