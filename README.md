# Permut8 Firmwares SDK

This repository contains documentation, examples, and helper tools for creating custom
firmwares for Sonic Charge Permut8. A firmware is a sandboxed GAZL program loaded by
Permut8 to replace the virtual DSP or one of the built-in operators. Most firmware source
in this SDK is written in Impala, a small C-like language that compiles to GAZL assembly.

The normal delivery format for a finished firmware is a `.p8bank` file. Console loading is
useful for development and debugging, but users should normally receive a bank file that
embeds the compiled code, optional IVG sticker, optional about text, and 30 program slots.

Permut8 saves the actual firmware code with the DAW project state. Reopening an old project
restores the embedded firmware code that was loaded into that Permut8 instance, not merely a
reference to an external `.gazl`, `.impala`, or `.p8bank` file.

## Technology Overview

- _Permut8 firmware_: a GAZL program loaded by Permut8 to replace DSP behavior.
- _Impala_: the C-like source language used by most example firmwares.
- _GAZL_: the typed virtual machine and readable assembly format used by Permut8 firmwares.
- _P8Bank_: the plain-text `Permut8BankV2` file format used to distribute firmware banks.
- _IVG_: the vector graphics format used for firmware sticker graphics.
- _ImpD_: the small imperative data language used by IVG.

## Repository Structure

- `docs`:
    - [Documentation Index](docs/README.md)
    - [Permut8 Firmware API](docs/Permut8%20Firmware%20API.md)
    - [Compiling and Loading Firmwares](docs/Compiling%20and%20Loading%20Firmwares.md)
    - [Creating P8Bank Files](docs/Creating%20P8Bank%20Files.md)
    - [Firmware Assets Guide](docs/Firmware%20Assets%20Guide.md)
    - [Validation](docs/Validation.md)
    - [Permut8 User Guide](docs/Permut8%20User%20Guide.md)

- `examples`:
    - Example `.p8bank` files, screenshots, and firmware source/assets.
    - `examples/Firmwares/ringmod_code.impala` is the best compact full-patch starting point.
    - `examples/Firmwares/linSubMod_code.impala` is the best compact mod-patch starting point.

- `tools`:
    - `bin`: prebuilt SDK helper executables and runtime scripts used by the documented
      compile, package, and validation commands.
    - `createP8Bank.pika`: wraps compiled GAZL plus optional logo/about assets into a `.p8bank`.
    - `gazlCompactor.pika`: strips comments and redundant whitespace from compiled GAZL
      for smaller release banks.
    - `update-firmware-toolchain.sh`: builds Unix tools in `tools/bin` when needed,
      rebuilds the Impala compiler, refreshes the firmware runtime files from the
      authoritative `GAZL` copy, and updates the vendored IVG renderer used for sticker
      validation.
    - `convert-user-guide.sh` and `bootstrap-docling.sh`: maintain generated user-guide docs.

- `GAZL`:
    - Vendored GAZL VM, Impala compiler, build scripts, tests, and documentation copied
      from [malstrom72/GAZL](https://github.com/malstrom72/GAZL). This folder is kept as
      a straight upstream copy where practical.
    - Includes the authoritative bundled PikaCmd source under `GAZL/externals/PikaCmd`;
      built PikaCmd executables are kept out of `GAZL/`.

- `IVG`:
    - Vendored IVG renderer, fonts, tools, tests, and documentation used for sticker graphics.

- `agents`:
    - Agent instruction packages for AI assistants working with this SDK. See
      [agents/permut8-firmware-writer](agents/permut8-firmware-writer/).

## Quick Start

In a consuming project, keep this SDK under `references/permut8-firmwares-sdk/`
and keep generated work outside the SDK checkout.

Compile the firmware:

```sh
references/permut8-firmwares-sdk/tools/bin/PikaCmd \
  references/permut8-firmwares-sdk/tools/bin/impala.pika \
  compile \
  <path-to-source.impala> \
  <path-to-compiled.gazl>
```

Package it as a firmware bank:

```sh
references/permut8-firmwares-sdk/tools/bin/PikaCmd \
  references/permut8-firmwares-sdk/tools/createP8Bank.pika \
  --name ringmod \
  --code <path-to-compiled.gazl> \
  --logo <path-to-logo.ivg> \
  --about <path-to-about.txt> \
  --compact true \
  --output <path-to-output.p8bank>
```

Omit `--compact true` if you deliberately want readable GAZL embedded in the bank during
debugging.

Load the generated `.p8bank` in Permut8. This compile/package/load path has been
verified with the RingMod example and is the recommended sanity check for the SDK.

The `PikaCmd` executable is still required for Impala firmware work because the
firmware compiler used by the original Permut8 development folder is written in
PikaScript. `PikaCmd` runs `impala.pika`, which loads `impalaCompiler.pika` and emits
the `.gazl` file that Permut8 can load.

## Firmware Authoring

Start with [Permut8 Firmware API](docs/Permut8%20Firmware%20API.md) for the host
globals, native functions, entry points, patch types, and performance rules exposed to
firmware code.

Use [Compiling and Loading Firmwares](docs/Compiling%20and%20Loading%20Firmwares.md)
when you want the direct console development workflow. Use
[Creating P8Bank Files](docs/Creating%20P8Bank%20Files.md) when you want the normal
distribution workflow.

For fast iteration, run `examples/Firmwares/Compile Loop OS X.command` or
`examples/Firmwares/Compile Loop Windows.bat` from the firmware code folder. The loop
regenerates `.gazl` whenever `.impala` changes; after the patch has been loaded once from
the Permut8 console, the console patch tool reloads the changed `.gazl` automatically.

Use [Firmware Assets Guide](docs/Firmware%20Assets%20Guide.md) for tape text,
firmware sticker graphics, special characters, and about text layout.

## Validation

Use [Validation](docs/Validation.md) for the practical checks before returning or
shipping a firmware:

1. Compile Impala to GAZL.
2. Package a `.p8bank`.
3. Check about text line count and width.
4. Render static IVG sticker graphics with `IVG2PNG` where possible.
5. Load the generated bank in Permut8 when plugin access is available.

## Development Folder

Permut8's development firmware folder is named:

```text
Permut8 Firmware Code
```

Common locations:

```text
macOS:   /Library/Application Support/Sonic Charge/Permut8 Firmware Code/
Windows: %PROGRAMFILES%\Sonic Charge\Permut8 Firmware Code
```

For a linked local development workflow, see
[Compiling and Loading Firmwares](docs/Compiling%20and%20Loading%20Firmwares.md#development-folder-linking).

## Documentation Notes

The files under `GAZL/` and `IVG/` are vendored subsystem snapshots. `GAZL/` is intended to
remain a straight copy of [malstrom72/GAZL](https://github.com/malstrom72/GAZL) where
practical. Prefer the top-level Permut8 docs for firmware authoring, and use the vendored
docs when you need exact language, VM, or renderer behavior.

AI tools have been used to assist with documentation and repetitive edits in this repository.
The original firmware examples, tools, and core subsystem code should be treated as the
authoritative source for behavior.
