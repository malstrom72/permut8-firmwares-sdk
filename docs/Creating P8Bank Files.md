# Creating P8Bank Files

Permut8 firmwares should normally be delivered as `.p8bank` files. Console loading is useful for hacking and iterative debugging, but a bank file is the normal delivery format for a firmware.

For the full documentation map, see [Documentation Index](README.md). For validation checks before returning or shipping a bank, see [Validation](Validation.md).

Permut8 bank files are plain-text `Permut8BankV2` documents. A firmware bank contains:

- `CurrentProgram`
- a `Programs` block with 30 programs, `A0` through `C9`
- a top-level `Firmware` block

The `Firmware` block contains:

```text
Firmware: {
	Name: "ringmodComp"
	Config: ""
	Code: {
		"... GAZL line ..."
	}
	Logo: {
		"... IVG line ..."
	}
	About: {
		"... about text line ..."
	}
}
```

`Code` stores the compiled `.gazl` text line by line. `Logo` stores an optional `.ivg` sticker graphic. `About` stores optional text shown from the firmware logo sticker.

The about text is displayed in Permut8's built-in console, which is **25 rows tall and 80 columns wide**. The console consumes 4 rows for overhead (command echo, leading blank, trailing blank, and the `sys>` prompt), leaving **21 rows for about text content**. Keep line count at or below 21 and each line at or below 80 characters, or the text will scroll off the top and the user will not see the beginning.

## Verified RingMod Path

This path has been tested end to end with the RingMod example:

1. compile the firmware `.impala` source to a `.gazl` file
2. wrap the compiled GAZL, IVG logo, and about text into a `.p8bank`
3. load the generated bank in Permut8

The generated bank loaded successfully in Permut8. This is the recommended proof path when checking that the SDK still works.

## Generate a Bank

Do not write generated firmware files into the SDK reference checkout. Keep
`references/permut8-firmwares-sdk/` as a read-only source of docs, examples, and tools unless
you are deliberately contributing SDK examples.

First compile Impala to GAZL:

```sh
cd references/permut8-firmwares-sdk/examples/Firmwares
./PikaCmd impala.pika compile \
  <path-to-source.impala> \
  <path-to-compiled.gazl>
cd ../../../..
```

Then wrap the compiled firmware into a bank with the PikaScript bank writer,
choosing the output path that fits your project:

```sh
references/permut8-firmwares-sdk/examples/Firmwares/PikaCmd \
  references/permut8-firmwares-sdk/tools/createP8Bank.pika \
  --name ringmod \
  --code <path-to-compiled.gazl> \
  --logo <path-to-logo.ivg> \
  --about <path-to-about.txt> \
  --output <path-to-output.p8bank>
```

Without `--template`, the writer starts from a clean bank. `CurrentProgram` is `A0`, and each program is an unnamed empty `Permut8ProgramV2`-style state:

```text
Permut8ProgramV2: {
	Modified: false
	InputLevel: "0.00000000"
	Limiter: "Off"
	FilterFreq: "---"
	FilterPlacement: "Output"
	FeedbackAmount: "0.00000000"
	FeedbackFlip: "Off"
	FeedbackInvert: "Off"
	OutputLevel: "0.00000000"
	Mix: "100.00000000"
	ClockFreq: "44.10000229 kHz"
	SyncMode: "Off"
	Reverse: "Off"
	Operator1: "0"
	Operand1High: "0x00"
	Operand1Low: "0x00"
	Operator2: "0"
	Operand2High: "0x00"
	Operand2Low: "0x00"
}
```

## Compact GAZL For Release

Compiled `.gazl` files are readable assembly text with labels, comments, and alignment
whitespace. The compactor removes comments and redundant whitespace so the code embedded in
the `.p8bank` is smaller.

For normal release packaging, let the bank writer compact the code while packaging:

```sh
references/permut8-firmwares-sdk/examples/Firmwares/PikaCmd \
  references/permut8-firmwares-sdk/tools/createP8Bank.pika \
  --name ringmodComp \
  --code <path-to-compiled.gazl> \
  --logo <path-to-logo.ivg> \
  --about <path-to-about.txt> \
  --compact true \
  --output <path-to-output.p8bank>
```

The compactor is intentionally simple. It processes GAZL text line by line, removes text
after `;` comments, collapses spaces and tabs between tokens, drops empty lines, and
preserves `DATs` string payloads verbatim so semicolons and spacing inside string data
survive. It is not an optimizer and does not change labels, instructions, constants, or data.

You can also run the compactor as a separate inspection step:

```sh
references/permut8-firmwares-sdk/examples/Firmwares/PikaCmd \
  references/permut8-firmwares-sdk/tools/gazlCompactor.pika \
  <path-to-compiled.gazl> \
  <path-to-compacted.gazl>
```

## Preserve an Existing Program Bank

If you want to keep the 30 program settings from an existing bank and replace only the embedded firmware, pass it as a template:

```sh
references/permut8-firmwares-sdk/examples/Firmwares/PikaCmd \
  references/permut8-firmwares-sdk/tools/createP8Bank.pika \
  --template "references/permut8-firmwares-sdk/examples/RingMod Firmware.p8bank" \
  --name ringmodComp \
  --code <path-to-compiled.gazl> \
  --logo <path-to-logo.ivg> \
  --about <path-to-about.txt> \
  --output <path-to-output.p8bank>
```

Without `--template`, the tool writes a minimal bank with 30 empty programs. When using a template, write to a new output path first and only replace the source bank after loading and verifying the generated bank in Permut8.

For a better user-test artifact, preserve the programs from the existing RingMod example bank and replace only the embedded firmware block with freshly compiled Impala output:

```sh
references/permut8-firmwares-sdk/examples/Firmwares/PikaCmd \
  references/permut8-firmwares-sdk/tools/createP8Bank.pika \
  --template "references/permut8-firmwares-sdk/examples/RingMod Firmware.p8bank" \
  --name ringmod \
  --code <path-to-compiled.gazl> \
  --logo <path-to-logo.ivg> \
  --about <path-to-about.txt> \
  --output <path-to-output.p8bank>
```

This keeps the useful RingMod programs and can be helpful when deliberately rebuilding an existing bank. For a new firmware, normally start from the clean no-template bank and only add named programs intentionally.

## Escaping

The bank writer stores every firmware, logo, and about-text line as a quoted string. It escapes:

- `"` as `\"`
- `\` as `\\`
- tab characters as `\t`

The output uses CRLF line endings, matching the example bank format.

The writer reads and writes firmware assets as single-byte `latin1` text. Some existing firmware-era assets contain non-UTF-8 bytes, for example IVG comments with names containing extended Latin characters. Do not change the writer to UTF-8 unless all existing assets have first been normalized and verified in Permut8.

## Authoring Guidance

When creating a firmware:

1. Write or update the `.impala` source in the consuming project.
2. Compile it to `.gazl`.
3. Create or update matching `_logo.ivg` and `_about.txt` files if needed.
4. Generate the `.p8bank` with `examples/Firmwares/PikaCmd tools/createP8Bank.pika`.
5. Treat the `.p8bank` path as the primary artifact.

Do not rely on the user copying source files into `Permut8 Firmware Code` unless they explicitly want the console development workflow.

When creating a brand-new firmware bank, normally start with the clean no-template output. When updating an existing firmware bank, use `--template` only when you deliberately want to keep its programs intact.

AI-specific workflow guidance lives in [../agents/permut8-firmware-writer](../agents/permut8-firmware-writer/).
