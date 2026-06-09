# Documentation Index

This directory contains the Permut8 firmware authoring documentation. Start with the
workflow that matches what you are trying to do, then fall back to subsystem references
only when you need exact language or renderer behavior.

## New Firmware Authors

- [Permut8 Firmware API](Permut8%20Firmware%20API.md): host API, native functions,
  globals, callback entry points, patch types, performance patterns, and minimal
  full-patch/mod-patch skeletons.
- [Firmware Assets Guide](Firmware%20Assets%20Guide.md): tape text, IVG sticker graphics,
  special characters, about text, and asset layout advice.
- [Operand Scaling Conventions](Operand%20Scaling%20Conventions.md): common mappings from
  raw operand bytes to delays, rates, and precise 16-bit values.
- [Validation](Validation.md): compile, package, asset, and loading checks before a
  firmware is returned or shipped.

## Development Workflow

- [Compiling and Loading Firmwares](Compiling%20and%20Loading%20Firmwares.md): Impala to
  GAZL compilation, reusable Impala snippets, development folder setup, console loading,
  debug behavior, and saved project behavior.
- [Creating P8Bank Files](Creating%20P8Bank%20Files.md): `.p8bank` file structure,
  `tools/createP8Bank.pika`, template usage, escaping, and release packaging.

## User-Facing Product Reference

- [Permut8 User Guide](Permut8%20User%20Guide.md): converted Markdown copy of the user
  guide.
- [Permut8 User Guide PDF](Permut8%20User%20Guide.pdf): original PDF user guide.

## Graphics And Language References

- [IVG Documentation](IVG%20Documentation.md): vector graphics language used for stickers.
- [ImpD Documentation](ImpD%20Documentation.md): imperative data language used by IVG.
- [GAZL Overview](../GAZL/docs/Overview.md): VM architecture and textual representation.
- [Impala Language Reference](../GAZL/docs/Impala.md): the Impala source language.
- [GAZL Instruction Set](../GAZL/docs/InstructionSet.md): opcode reference.
- [GAZL Usage Example](../GAZL/docs/UsageExample.md): compile and run a simple program.
- [PikaScript Documentation](PikaScript/PikaScript%20Documentation.txt): PikaScript
  language reference for SDK tools such as `tools/createP8Bank.pika`.
- [PikaCmd Documentation](PikaScript/PikaCmd%20Documentation.txt): command runner
  reference.

## Vendored Subsystem Docs

- [IVG README](../IVG/README.md)
- [IVG docs](../IVG/docs/IVG%20Documentation.md)
- [ivgfont docs](../IVG/docs/ivgfont%20Documentation.md)
- [NuXPixels docs](../IVG/docs/NuXPixels%20Documentation.md)
- [GAZL README](../GAZL/README.md)

The vendored `IVG/` and `GAZL/` folders contain their own documentation because they are
usable subsystems. `GAZL/` is intended to remain a straight copy of
[malstrom72/GAZL](https://github.com/malstrom72/GAZL) where practical. For Permut8
firmware work, use the Permut8-specific docs above first.
