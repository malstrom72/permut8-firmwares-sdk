# Vendored IVG

IVG is Magnus Lidström's vector graphics format and renderer, upstream at
<https://github.com/malstrom72/IVG>. It is vendored here by **file copy**, not as a submodule, so
nothing in `.git` records which upstream revision these files came from. This file is that record.

**Pinned at `873181f60eb0b28d5aa78c8e60e8edbf36605474`** (2026-10-13, "Rebuild the IVGFiddle WASM
with the fiddle budget and ptrdiff_t substrings") - the IVG-2 freeze on IVG `main`. Per Magnus's decision, the SDKs
vendor the IVG main freeze rather than the IVG revision embedded in the shipping Permut8 (svn
r25291); a sticker that renders here may therefore exercise fixes the shipping plugin predates, so a
final in-plugin check still counts. Never take anything from upstream's `IVG-3` branch.

| Consumer | Pin |
|---|---|
| Permut8 firmwares SDK | `873181f` |

The move from the previous freeze `651fdab` brings a count-based resource budget per render, now
**required** (#268, 5baf7e5, 421f819): IMPD takes an
`IMPD::IMPDBudget` (characters, statements) and IVG an `IVG::IVGBudget` that adds path segments
and pixels, with defaults of 1e8 characters, 1e6 statements, 1e7 path segments and 5e8 pixels
(7d67813). A host creates one budget per render, keeps it alive for the whole render, and passes
it to both `IVGExecutor` and `Interpreter`; an oversized document stops with an error instead of
exhausting memory or time. The vendored `tools/IVG2PNG.cpp` does exactly that, and charges
external fonts to the same budget; IVGFiddle gets a budget sized to its 64 MB WebAssembly heap
(6819671). The SDK has no IVG host code of its own. Also: substrings indexed with `ptrdiff_t`
(82f1af2), range-checked scaled pattern bounds and two number/name parsing edge cases (9051621),
the SVG arc centre at the chord's midpoint when the radii only just fit (cc846c6), IVG2PNG reading
its input and fonts in binary mode (2cbd2fd), and the IVGFiddle module-instance fix (cd35109, see
Local patches). Rendered with IVG2PNG built from `651fdab`, `d869556` and `873181f`, all 7 example
stickers and `tests/font-rendering.ivg` (the one document here that exercises text) produce
byte-identical PNGs, on both Windows and macOS - none comes near the budget defaults.

Before the first pin the copy was mixed-vintage - `src/` matched upstream `main` as of 3360ae2..813a7ab
(2026-05/09) while `README.md` and the docs lagged further. The now-removed
`SHIPPING_MICROTONIC_VERSION.md` recorded the copy's origin as a curated import at upstream
`c016809d2f120e74eca4d64d61b134ee8dfb563d`, kept as the reference for the IVG inside the shipping
*Microtonic*; Magnus's 2026-10 decision that the SDKs track the IVG-2 freeze supersedes that
arrangement. The freeze brings, among other things, the NuXPixels UBSan/overflow fixes (7d0c451:
PolygonMask stops stepping an edge past its end when skipping rows; 1a109b6: SVG arc flags read as
single 0/1 characters; ecd2075, 83e25a4) and the arcSweep `fabs` fix.

## Local patches

None at this pin - every vendored file is byte-identical to upstream `873181f`. History worth
knowing: the pre-freeze copy carried ONE deliberate local patch, documented only in
`SHIPPING_MICROTONIC_VERSION.md` - `tools/ivgfiddle/output/setupModule.js` deferred `runIVG()`
until the modularized Emscripten runtime instance had replaced the factory in the global `Module`,
avoiding `Module.lengthBytesUTF8 is not a function`. The 651fdab refresh replaced that file with
upstream's restructured version, on the then-mistaken belief that all drift was pin skew, and the
race came back: upstream's `onRuntimeInitialized` callback runs before the factory's promise
resolves, while `Module` is still the factory. Upstream fixed it in cd35109 by taking the instance
from `this` inside the callback, so at this pin the patch is no longer needed. If a local patch
ever becomes necessary again, record it HERE, not in a side file.

## What is taken

This is a **partial copy**: `LICENSE`, `README.md`, `src/`, `fonts/`, and the
`externals/NuX`, `externals/libpng`, `externals/zlib` subtrees are complete; `docs/`, `tests/`, and
`tools/` are curated subsets (upstream's internal docs, fuzz corpora, CI, and project files are
deliberately excluded). One file is SDK-local and NOT upstream's - preserve it across bumps:

- `tests/font-rendering.ivg`

## Bumping

From the repository root, with the pin above as the `..` endpoint so you can read what you are taking:

```
git clone https://github.com/malstrom72/IVG.git /tmp/ivg
git -C /tmp/ivg log --oneline 873181f..origin/main
```

Refresh **only the files already vendored** (every `git ls-files IVG` path except the two SDK-local
files) from the new revision; do not blind-copy the upstream tree, and check for upstream deletions
and for new files in the complete subtrees listed above. Then:

1. update the pin in this file;
2. rebuild `tools/bin/IVG2PNG` (macOS) and `tools/bin/IVG2PNG.exe` (Windows) via
   `tools/update-firmware-toolchain.{sh,cmd}`;
3. run `tools/sync-ivg-docs.sh` so the top-level `docs/` mirror follows;
4. re-render the example stickers (see `docs/Validation.md`) as a smoke test.
