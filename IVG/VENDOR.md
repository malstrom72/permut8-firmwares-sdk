# Vendored IVG

IVG is Magnus Lidström's vector graphics format and renderer, upstream at
<https://github.com/malstrom72/IVG>. It is vendored here by **file copy**, not as a submodule, so
nothing in `.git` records which upstream revision these files came from. This file is that record.

**Pinned at `651fdabd4384007738d66266898d55b77242babe`** (2026-10-07, "Take the absolute sweep with
fabs in arcSweep") - the IVG-2 freeze. Per Magnus's decision, the SDKs vendor this freeze rather
than the IVG revision embedded in the shipping Permut8 (svn r25291); a sticker that renders here
may therefore exercise fixes the shipping plugin predates, so a final in-plugin check still counts.

| Consumer | Pin |
|---|---|
| Permut8 firmwares SDK | `651fdab` |

Before this pin the copy was mixed-vintage - `src/` matched upstream `main` as of 3360ae2..813a7ab
(2026-05/09) while `README.md` and the docs lagged further - and nothing recorded any of it. The
freeze brings, among other things, the NuXPixels UBSan/overflow fixes (7d0c451: PolygonMask stops
stepping an edge past its end when skipping rows; 1a109b6: SVG arc flags read as single 0/1
characters; ecd2075, 83e25a4) and the arcSweep `fabs` fix.

## What is taken

This is a **partial copy**: `LICENSE`, `README.md`, `src/`, `fonts/`, and the
`externals/NuX`, `externals/libpng`, `externals/zlib` subtrees are complete; `docs/`, `tests/`, and
`tools/` are curated subsets (upstream's internal docs, fuzz corpora, CI, and project files are
deliberately excluded). Two files are SDK-local and NOT upstream's - preserve them across bumps:

- `SHIPPING_MICROTONIC_VERSION.md`
- `tests/font-rendering.ivg`

## Bumping

From the repository root, with the pin above as the `..` endpoint so you can read what you are taking:

```
git clone https://github.com/malstrom72/IVG.git /tmp/ivg
git -C /tmp/ivg log --oneline 651fdab..origin/main
```

Refresh **only the files already vendored** (every `git ls-files IVG` path except the two SDK-local
files) from the new revision; do not blind-copy the upstream tree, and check for upstream deletions
and for new files in the complete subtrees listed above. Then:

1. update the pin in this file;
2. rebuild `tools/bin/IVG2PNG` (macOS) and `tools/bin/IVG2PNG.exe` (Windows) via
   `tools/update-firmware-toolchain.{sh,cmd}`;
3. run `tools/sync-ivg-docs.sh` so the top-level `docs/` mirror follows;
4. re-render the example stickers (see `docs/Validation.md`) as a smoke test.
