# Packaging Guidance

The SDK documents two practical workflows.

## `.p8bank` Delivery

Use a `.p8bank` file for normal user-facing output.

A bank embeds:

- the compiled `.gazl` firmware code;
- optional `.ivg` sticker graphics;
- optional about text;
- 30 program slots;
- the current program selection.

Generate banks with `tools/createP8Bank.pika`. Start from a clean no-template bank for
brand-new firmwares. Use `--template` only when deliberately preserving the 30 programs
from an existing bank.

For release-sized banks, pass `--compact true` to `tools/createP8Bank.pika`. The compactor
strips comments and redundant whitespace while preserving `DATs` string payloads; it is not a
semantic optimizer. Use `tools/gazlCompactor.pika` directly only when you need a separate
compacted `.gazl` file for inspection.

## Console Development

Use direct console loading when the user explicitly wants an edit/compile/reload workflow
inside Permut8.

Console loading is useful because:

- `DEBUG` is non-zero;
- `trace()` and Impala assertions are enabled;
- optional configuration text can be passed after the firmware name;
- it avoids rebuilding a bank after every edit;
- with `Compile Loop OS X.command` or `Compile Loop Windows.bat` running, saving `.impala`
  regenerates `.gazl`, and the console patch tool reloads the active firmware when that
  `.gazl` changes.

Console loading is not the normal delivery format. For finished firmware output, package a
`.p8bank`.

## Asset Packaging

For a complete firmware bank, keep the firmware source and assets together:

```text
myfirmware_code.impala
myfirmware_code.gazl
myfirmware_logo.ivg
myfirmware_about.txt
```

The firmware name normally matches the prefix before `_code`, `_logo`, and `_about`.

## Generated User Artifacts

When returning generated firmware work, report the `.p8bank` path as the primary artifact.
Also mention source, logo, and about files when they were created or changed, but do not ask
the user to manually copy source files into `Permut8 Firmware Code` unless they requested the
console development workflow.
