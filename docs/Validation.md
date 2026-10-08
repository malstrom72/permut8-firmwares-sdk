# Validation

Use these checks before returning or shipping a Permut8 firmware bank.

## Compile Impala

Compile the firmware source to GAZL from a consuming project that has this SDK cloned under
`references/permut8-firmwares-sdk/`:

```sh
references/permut8-firmwares-sdk/tools/bin/NuXJS \
  references/permut8-firmwares-sdk/tools/bin/impala.nuxjs.js \
  <path-to-source.impala> \
  <path-to-compiled.gazl>
```

On Windows:

```bat
references\permut8-firmwares-sdk\tools\bin\NuXJS.exe ^
  references\permut8-firmwares-sdk\tools\bin\impala.nuxjs.js ^
  <path-to-source.impala> ^
  <path-to-compiled.gazl>
```

A successful compile proves the Impala source can be translated to the GAZL text that
Permut8 loads and that `.p8bank` files embed.

## Check Native Signatures

Impala 2 checks native calls at compile time, so this is no longer a separate step. Import
the Permut8 native prototypes and every call is checked against them, with a caret on the
offending argument:

```impala
import "permut8natives.impala"
```

Copy [`impala/permut8natives.impala`](../impala/permut8natives.impala) next to your firmware
source, or import it by relative path. A wrong argument type or count then fails the compile:

```text
mysynth.impala:42:19: error[E406]: Argument type mismatch for argument 1 when calling write (pointer vs expected int)
```

Importing is optional. The name-only `extern native abort` form still compiles and still
asserts nothing, so declare prototypes where you want the check. Do not do both for the same
name in one program — the top-level namespace is flat, so that is a duplicate declaration.

This replaces the `gazl-validate` pass used through Impala 1.0. Upstream retired that tool
along with its `docs/nativeCallbackSignatures.gazl` manifest: a prototype the compiler reads
cannot drift out of the language it describes, the way a separately-compared manifest could.

## Optional: Compact GAZL

For release banks, compact the compiled GAZL during packaging:

```sh
references/permut8-firmwares-sdk/tools/bin/NuXJS \
  references/permut8-firmwares-sdk/tools/createP8Bank.nuxjs.js \
  --name ringmod \
  --code <path-to-compiled.gazl> \
  --logo <path-to-logo.ivg> \
  --about <path-to-about.txt> \
  --compact true \
  --output <path-to-output.p8bank>
```

This reduces bank size, but it is still only a text transformation; a successful compaction
does not replace a compile check or a Permut8 load test.

## Package A Bank

Package the compiled code and optional assets with the bank writer:

```sh
references/permut8-firmwares-sdk/tools/bin/NuXJS \
  references/permut8-firmwares-sdk/tools/createP8Bank.nuxjs.js \
  --name ringmod \
  --code <path-to-compiled.gazl> \
  --logo <path-to-logo.ivg> \
  --about <path-to-about.txt> \
  --compact true \
  --output <path-to-output.p8bank>
```

Omit `--compact true` only when you need readable GAZL embedded in the bank for debugging.

Do not write generated firmware files into `references/permut8-firmwares-sdk/` unless you
are deliberately contributing SDK examples.

Use `--template` only when you deliberately want to preserve the 30 programs from an
existing bank. For a brand-new firmware, start from a clean no-template bank and add named
programs intentionally.

For user-facing firmware banks, check that the program slots are intentional. A release bank
should normally include useful named examples or deliberately chosen empty/default slots,
not accidental untouched defaults. The programs should exercise the firmware's important
modes, operand ranges, clock/sync behavior, and host-side feedback/filter/mix controls.

## Check About Text

The about text is shown in Permut8's built-in console. The visible content area is 21 rows
by 80 columns after command/prompt overhead. Lines longer than 80 characters wrap and cost
another row.

Check a file before packaging:

```sh
awk 'END{print NR" lines"} {if(length>80) print "LINE "NR" TOO LONG ("length")"}' \
  <path-to-about.txt>
```

Keep about text at or below 21 lines and 80 columns unless you deliberately want it to
scroll.

## Render Static IVG Stickers

Build the local IVG renderer:

```sh
references/permut8-firmwares-sdk/tools/update-firmware-toolchain.sh
```

Render a sticker against Permut8's tape-like background:

```sh
references/permut8-firmwares-sdk/tools/bin/IVG2PNG \
  --fonts references/permut8-firmwares-sdk/IVG/fonts \
  --background "#b8a888" \
  <path-to-logo.ivg> \
  <path-to-preview.png>
```

Use this check for static `.ivg` sticker files. It catches parse errors and many color,
font, bounds, and rasterization problems. It does not prove how a dynamic or host-bound
graphic behaves inside Permut8.

## Check Panel Text Rows

For fixed 4+24+1+24 rows, verify row length:

```sh
python3 -c 'print(len("    |----- LEFT DELAY -----| |----- RIGHT DELAY ----|"))'
```

Free-form rows are acceptable when the firmware does not use fixed per-switch labels, but
they should still be short enough to fit the tape cleanly.

Also check the tape as a user-facing control surface:

- Rows 0-3 line up with instruction 1 operator positions 1-4.
- Rows 4-7 line up with instruction 2 operator positions 1-4.
- Mode-per-row designs do not put multiple operator positions on the same row.
- Operand-high and operand-low meanings are visible when the switches have stable meanings.
- Fixed switch layouts use the 24-character operand spans where practical.
- Stacked vertical labels are used only for real per-switch column layouts.
- The final tape is checked in Permut8 or against a screenshot when available.

## Run The Firmware

Compiling proves a firmware is well-formed; it does not prove it runs. The SDK can execute a compiled
`.gazl` outside the plugin:

```sh
bash tools/runPermut8Firmware.sh examples/Firmwares/ringmod_code.gazl
```

```bat
tools\runPermut8Firmware.cmd examples\Firmwares\ringmod_code.gazl
```

`tools/permut8Host.nuxjs.js` wraps the **unmodified** firmware in a pure-GAZL host - a delay line, a
fixed-seed pseudo-audio generator, and implementations of `yield`/`read`/`write`/`trace` - and
`tools/bin/GAZLCmd` runs it for 100,000 frames, printing one checksum of everything the firmware
produced. The firmware is copied in verbatim; nothing is patched.

This catches what a compile cannot: runaway loops, memory violations, and firmwares that produce
silence. It also runs the entry points a compile never touches - `init()`, `update()`, `reset()` and
the audio loop itself.

The checksum is an **equality oracle**. It tells you whether output changed, not whether it is
correct. That makes it the right tool for exactly one question - *did this change anything?* - which
is the question you have after a refactor, a toolchain bump, a GAZL re-mirror, or a port to newer
Impala idioms. It is the wrong tool for "does this sound good".

To check every example at once against committed expectations:

```sh
bash tools/checkPermut8Firmwares.sh
```

Baselines live in `tools/permut8FirmwareChecksums.txt`. When you change DSP on purpose, refresh them
with `bash tools/checkPermut8Firmwares.sh --update` and review the diff - each changed line is a
firmware whose audio you altered, so an unexpected one is a bug you just caught.

The harness drives the standard firmware API only. A firmware without `process()`, `operate1()` or
`operate2()`, or a full patch that does not declare `signal`, is rejected rather than guessed at.

## Load In Permut8

Running the harness is not a substitute for this step. It exercises DSP behavior against a synthetic
host; it says nothing about how Permut8 itself loads the bank, or about anything the harness stubs
out. When plugin access is available, load the generated `.p8bank` in Permut8 and verify:

- the bank loads without restoring the default firmware;
- the expected firmware name appears;
- the sticker displays correctly;
- clicking the sticker shows readable about text;
- parameters, switches, LEDs, and reset behavior match the firmware design;
- saving and reopening a DAW project restores the embedded code version you intended.

Do not treat compile/package/render checks as proof of runtime DSP behavior. They prove the
assets are structurally valid; the generated bank still needs a plugin load test when exact
behavior matters.
