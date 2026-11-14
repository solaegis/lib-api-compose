# Documentation

This site is built with [MkDocs](https://www.mkdocs.org/) and [Material for MkDocs](https://squidfunk.github.io/mkdocs-material/)
from the Markdown in `docs/`, and published to GitHub Pages by `.github/workflows/docs.yaml`.

## Preview locally

```bash
task docs:serve      # first run creates .venv-docs and installs requirements-docs.txt
```

Open `http://127.0.0.1:8000`. Pages reload as you save.

## Build and check

```bash
task docs:build
```

This runs:

1. **`scripts/check-api-docs.sh`** —
    - every public function in `src/*.lua` (`function LAC.X` or `function Module.X`, names not starting with `_`)
      must have a `` ### `Module.X` `` heading somewhere in `docs/reference/`;
    - every fenced `lua` block in `docs/` must parse as Lua (checked with LuaJIT or Lua).
2. **`mkdocs build --strict`** — any broken link, missing anchor or page not in the nav fails the build.

CI runs the same steps on every pull request.

## Conventions

- **Reference pages** use one `` ### `Module.Function` `` heading per function, then: a `text` code block with
  the signature, a parameters table, returns, notes, an optional example, and *Since x.y.z*.
- **Signatures** go in ` ```text ` blocks (they aren't valid Lua). Use ` ```lua ` only for complete, runnable
  snippets — the check parses them.
- **Examples** start with `local LAC = LibApiCompose` so they work when pasted alone.
- **Record tables** have the columns Field, Type, ZOS source, Notes.
- Link between pages with relative paths to `.md` files (`../reference/core.md#lacsafecall`). Heading anchors
  are lowercase with punctuation removed.
- The changelog page includes the root `CHANGELOG.md`; edit that file, not `docs/changelog.md`.

## Publishing

Pushing to `main` with changes under `docs/`, `src/`, `mkdocs.yml`, `CHANGELOG.md` or `requirements-docs.txt`
builds and deploys the site. The repository's **Settings → Pages → Source** must be **GitHub Actions**.
