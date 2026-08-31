# Vendored NuXJS

NuXJS is Magnus Lidström's own ES5.1 JavaScript engine, BSD 2-Clause, upstream at
<https://github.com/malstrom72/NuXJS>. It is vendored here by **file copy**, not as a submodule, so
nothing in `.git` records which upstream revision these files came from. This file is that record.

**Pinned at `f381ea3528a5e57069cdb959c6096e207573a940`** (2026-08-30, "The quick-hash tables credit
their real origin"). Upstream has only a `main` branch; a `NuXJS` clone that happens to sit on some
other branch is local work, not a release.

Bumped in the Permut8 firmwares SDK from `ece071b021d7ad10167928725fd8bea7661810fc` (2026-07-29, "Add
printErr() helper to NuXJS REPL") when the SDK moved to Impala 2. The REPL change worth knowing about
in that range: the hidden 60-second time-out is gone and is now an opt-in `-T` / `--timeout`, so a
long compile no longer dies at one minute. The rest is engine conformance work (Date, `Math.round`,
Unicode 3.0 identifier tables) plus a faster `toFixed`/`toExponential`/`toPrecision`.

Only five files are taken:

| Vendored | Upstream |
|---|---|
| `LICENSE` | `LICENSE` |
| `src/NuXJS.cpp` `src/NuXJS.h` `src/stdlibJS.cpp` | same paths |
| `tools/NuXJSREPL.cpp` | same path |

`tools/NuXJSREPL.cpp` supplies the host globals the repo's scripts rely on - `print`, `printErr`,
`read` - so a bump that changes them ripples into `tools/gazl-validate.nuxjs.js` and the Impala front
ends.

## Bumping

From the repository root, with the pin above as the `..` endpoint so you can read what you are taking:

```
git clone https://github.com/malstrom72/NuXJS.git /tmp/nuxjs
git -C /tmp/nuxjs log --oneline ece071b..origin/main
cp /tmp/nuxjs/LICENSE externals/NuXJS/LICENSE
cp /tmp/nuxjs/src/NuXJS.cpp /tmp/nuxjs/src/NuXJS.h /tmp/nuxjs/src/stdlibJS.cpp externals/NuXJS/src/
cp /tmp/nuxjs/tools/NuXJSREPL.cpp externals/NuXJS/tools/
bash build.sh
```

Then update the pin in this file. Expect `src/stdlibJS.cpp` to show a whole-file diff even for a small
change: it is the minified JS standard library re-encoded as C string literals, so any edit reflows
every line.
