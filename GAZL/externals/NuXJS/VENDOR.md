# Vendored NuXJS

NuXJS is Magnus Lidström's own ES5.1 JavaScript engine, BSD 2-Clause, upstream at
<https://github.com/malstrom72/NuXJS>. It is vendored here by **file copy**, not as a submodule, so
nothing in `.git` records which upstream revision these files came from. This file is that record.

**Pinned at `f49acdd2e98f16ddda8725477b06eee730b6a79e`** (2026-10-08, the freeze Magnus declared for
the cross-repo NuXJS sync). Take releases from `main` only. Upstream also publishes work-in-progress
branches (`ES51` and others), and a local `NuXJS` clone sitting on one of those is work in progress,
not a release.

Bumped from `5fb318dac900069849206ada8a1920e73efd3a51` (2026-08-31). The range rewrites decimal
conversion with exact integer arithmetic in both directions (parsing near-ties now lands on the
mandated double; printing is shortest-round-trip with ties to even as in V8), throws compile errors
once from the root compiler (fixing a Windows stack overflow), fixes `with`-binding calls' `this`
and a sort-comparator non-termination, and settles `MAX_NESTED_COMPILE_DEPTH` at 128 after an
excursion to 48 that refused to load the JSPEG-generated `impalaCompiler.js` (which needs 57
levels). That excursion (`25b04d0`) was caught by this SDK's firmware checksum suite and reverted
upstream before this pin; do not vendor anything between `5fb318d` and `f49acdd`.

Verified at this pin: all ten `examples/Firmwares` sources recompile and all ten run to identical
output checksums under the Permut8 host harness; the emitted GAZL is token-identical apart from
random string-label suffixes (and the `DATA` row re-wrapping those cause). None of the examples'
float constants land on the exact-conversion tie cases, so the committed `.gazl` files are
unchanged by this bump and were left as they are.

Earlier, bumped from `ece071b021d7ad10167928725fd8bea7661810fc` (2026-07-29, "Add printErr() helper to
NuXJS REPL") when the SDK moved to Impala 2. The REPL change worth knowing about in that range: the
hidden 60-second time-out is gone and is now an opt-in `-T` / `--timeout`, so a long compile no longer
dies at one minute. The rest was engine conformance work (Date, `Math.round`, Unicode 3.0 identifier
tables) plus a faster `toFixed`/`toExponential`/`toPrecision`.

Only five files are taken:

| Vendored | Upstream |
|---|---|
| `LICENSE` | `LICENSE` |
| `src/NuXJS.cpp` `src/NuXJS.h` `src/stdlibJS.cpp` | same paths |
| `tools/NuXJSREPL.cpp` | same path |

`tools/NuXJSREPL.cpp` supplies the host globals the repo's scripts rely on - `print`, `printErr`,
`read`, `write` - so a bump that changes them ripples into `tools/createP8Bank.nuxjs.js`,
`tools/gazlCompactor.nuxjs.js` and the Impala front ends.

## Bumping

From the repository root, with the pin above as the `..` endpoint so you can read what you are taking:

```
git clone https://github.com/malstrom72/NuXJS.git /tmp/nuxjs
git -C /tmp/nuxjs log --oneline f49acdd..origin/main
cp /tmp/nuxjs/LICENSE externals/NuXJS/LICENSE
cp /tmp/nuxjs/src/NuXJS.cpp /tmp/nuxjs/src/NuXJS.h /tmp/nuxjs/src/stdlibJS.cpp externals/NuXJS/src/
cp /tmp/nuxjs/tools/NuXJSREPL.cpp externals/NuXJS/tools/
bash build.sh
```

Then update the pin in this file. Expect `src/stdlibJS.cpp` to show a whole-file diff even for a small
change: it is the minified JS standard library re-encoded as C string literals, so any edit reflows
every line.
