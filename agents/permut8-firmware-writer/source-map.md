# Source Map

Use these repository files as the grounding map for Permut8 firmware work.

## Core SDK References

- [README.md](../../README.md): repository structure, terminology, quick start, and
  high-level constraints.
- [docs/README.md](../../docs/README.md): documentation index grouped by reader goal.
- [docs/Permut8 Firmware API.md](../../docs/Permut8%20Firmware%20API.md): host API,
  native functions, globals, entry points, patch types, performance rules, and minimal
  skeletons.
- [docs/Compiling and Loading Firmwares.md](../../docs/Compiling%20and%20Loading%20Firmwares.md):
  Impala compile workflow, firmware development folder, console loading, debug behavior,
  and saved project behavior.
- [docs/Creating P8Bank Files.md](../../docs/Creating%20P8Bank%20Files.md): bank file
  structure, `tools/createP8Bank.pika`, template usage, escaping, and release packaging.
- [docs/Firmware Assets Guide.md](../../docs/Firmware%20Assets%20Guide.md): tape text,
  IVG sticker graphics, CustomBBL special characters, and about text.
- [docs/Validation.md](../../docs/Validation.md): practical compile, package, asset, and
  load checks.

## Product Reference

- [docs/Permut8 User Guide.md](../../docs/Permut8%20User%20Guide.md): product behavior,
  front-panel terminology, parameters, MIDI control, and user-facing feature descriptions.
- [docs/Permut8 User Guide.pdf](../../docs/Permut8%20User%20Guide.pdf): original user
  guide source.

## Firmware Examples

- [examples/Firmwares/ringmod_code.impala](../../examples/Firmwares/ringmod_code.impala):
  compact full-patch reference.
- [examples/Firmwares/linSubMod_code.impala](../../examples/Firmwares/linSubMod_code.impala):
  compact mod-patch reference.
- [examples/Firmwares/pong_code.impala](../../examples/Firmwares/pong_code.impala):
  panel text and multi-tap behavior reference.
- [examples/Firmwares/bender_code.impala](../../examples/Firmwares/bender_code.impala):
  mode-per-row panel text and waveshaping reference.
- [examples/Firmwares/beatrick_code.impala](../../examples/Firmwares/beatrick_code.impala):
  plain descriptive panel text, step-oriented behavior, and about text reference.
- [examples/Firmwares](../../examples/Firmwares): source and compiled GAZL examples,
  plus optional logo and about assets where available.
- [examples/Firmwares/Impala Snippets.txt](../../examples/Firmwares/Impala%20Snippets.txt):
  copy-paste Impala utility snippets, including Permut8-style exponential tables and
  string/numeric helpers. Use only the needed snippets because Impala has no source include
  mechanism.
- [examples/screenshots](../../examples/screenshots): screenshots of example banks and
  no-firmware state for visual alignment.

## Tools

- [tools/createP8Bank.pika](../../tools/createP8Bank.pika): bank writer.
- [tools/gazlCompactor.pika](../../tools/gazlCompactor.pika): optional release-size GAZL
  text compactor.
- [tools/update-firmware-toolchain.sh](../../tools/update-firmware-toolchain.sh):
  builds Unix tools in `tools/bin` when needed, rebuilds the Impala compiler, refreshes the
  firmware runtime files in `examples/Firmwares` from the authoritative `GAZL` copy, and
  builds the IVG renderer for sticker validation.
- [tools/convert-user-guide.sh](../../tools/convert-user-guide.sh): regenerates the
  Markdown user guide from source material.
- [GAZL/externals/PikaCmd](../../GAZL/externals/PikaCmd): bundled PikaScript command
  runner source from the vendored [malstrom72/GAZL](https://github.com/malstrom72/GAZL)
  copy. General runtime commands should use `tools/bin/PikaCmd`; firmware-folder compile
  loops use the copied `examples/Firmwares/PikaCmd`. Use this source folder only when
  rebuilding the runtime.
- [docs/PikaScript](../../docs/PikaScript): local PikaScript and PikaCmd documentation
  copied from [malstrom72/PikaScript](https://github.com/malstrom72/PikaScript).

## Language And Renderer References

- [GAZL/README.md](../../GAZL/README.md): GAZL subsystem overview.
- [GAZL/docs/Impala.md](../../GAZL/docs/Impala.md): Impala language quick start.
- [GAZL/docs/Overview.md](../../GAZL/docs/Overview.md): VM architecture and assembly model.
- [GAZL/docs/InstructionSet.md](../../GAZL/docs/InstructionSet.md): opcode reference.
- [IVG/README.md](../../IVG/README.md): IVG subsystem overview.
- [docs/IVG Documentation.md](../../docs/IVG%20Documentation.md): IVG language reference.
- [docs/ImpD Documentation.md](../../docs/ImpD%20Documentation.md): ImpD language reference.
- [IVG/docs/ivgfont Documentation.md](../../IVG/docs/ivgfont%20Documentation.md): IVG font
  format reference.

Prefer the top-level Permut8 docs for firmware behavior. Use GAZL and IVG references when
exact language, VM, or renderer behavior matters.
