# Validation

Use these checks before returning or shipping a Permut8 firmware bank.

## Compile Impala

Compile the firmware source to GAZL from a consuming project that has this SDK cloned under
`references/permut8-firmwares-sdk/`:

```sh
cd references/permut8-firmwares-sdk/examples/Firmwares
./PikaCmd impala.pika compile \
  <path-to-source.impala> \
  <path-to-compiled.gazl>
cd ../../../..
```

On Windows:

```bat
CD references\permut8-firmwares-sdk\examples\Firmwares
PikaCmd impala.pika compile ^
  <path-to-source.impala> ^
  <path-to-compiled.gazl>
CD ..\..\..\..
```

A successful compile proves the Impala source can be translated to the GAZL text that
Permut8 loads and that `.p8bank` files embed.

## Optional: Compact GAZL

For release banks, compact the compiled GAZL during packaging:

```sh
references/permut8-firmwares-sdk/examples/Firmwares/PikaCmd \
  references/permut8-firmwares-sdk/tools/createP8Bank.pika \
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
references/permut8-firmwares-sdk/examples/Firmwares/PikaCmd \
  references/permut8-firmwares-sdk/tools/createP8Bank.pika \
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
references/permut8-firmwares-sdk/tools/build-ivg2png.sh
```

Render a sticker against Permut8's tape-like background:

```sh
references/permut8-firmwares-sdk/IVG/output/IVG2PNG \
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

## Load In Permut8

When plugin access is available, load the generated `.p8bank` in Permut8 and verify:

- the bank loads without restoring the default firmware;
- the expected firmware name appears;
- the sticker displays correctly;
- clicking the sticker shows readable about text;
- parameters, switches, LEDs, and reset behavior match the firmware design;
- saving and reopening a DAW project restores the embedded code version you intended.

Do not treat compile/package/render checks as proof of runtime DSP behavior. They prove the
assets are structurally valid; the generated bank still needs a plugin load test when exact
behavior matters.
