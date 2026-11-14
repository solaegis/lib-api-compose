# Publishing — LibApiCompose

1. Update `CHANGELOG.md` under the release version.
2. Tag `vX.Y.Z` (semver). CI builds ZIP, sets `## Version:` and encoded `## AddOnVersion:`.
3. ESOUI upload when `ESOUI_ADDON_ID != 0` (currently `0` — GitHub Releases only until listed).
4. Category on ESOUI: **Libraries**.
5. Document `## DependsOn: LibApiCompose>=N` for consumers (N = encoded AddOnVersion).

Do not embed this library inside product ZIPs.
