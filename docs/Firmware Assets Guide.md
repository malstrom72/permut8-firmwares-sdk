# Firmware Assets Guide

A Permut8 firmware can ship with three extras beyond the code itself: tape text, an IVG sticker, and an about text. All three get embedded in the `.p8bank` file.

For the full documentation map, see [Documentation Index](README.md). For packaging, see [Creating P8Bank Files](Creating%20P8Bank%20Files.md). For structural checks, see [Validation](Validation.md).

---

## Tape Text

The `panelTextRows` array replaces Permut8's built-in screen print with your own labels. All 8 rows are visible on the tape simultaneously — rows 0–3 on instruction 1's strip, rows 4–7 on instruction 2's — like a physical paper label. The rows align with the operator knob positions, so the whole thing acts as a permanent reference chart for every mode at once.

Each instruction's operator knob currently has five positions: position 0 is the stock NOP/OFF position by convention, and positions 1–4 are the four active operator rows. The four tape rows for a strip line up with positions 1–4, not 0–3. Rows 0–3 label instruction 1 positions 1–4; rows 4–7 label instruction 2 positions 1–4. Position 0 has no tape row. When a firmware reassigns the operator knob to custom modes, keep position 0 as a clean bypass unless there is a deliberate reason to do otherwise.

An empty string `""` means no tape on that row. A single space `" "` keeps a blank row. The pointer doesn't need to point at constant data, but the text shouldn't change after `init()` returns.

### Approaches — with full examples

There is no single format. The right choice depends on what the firmware does. Here are the main patterns used across the examples.

---

**Simple: label the operands, leave the rest blank**

Used by ringmod. The firmware doesn't reassign the operator knob to new modes, so most rows are blank and only rows 3 and 7 carry operand labels.

```impala
readonly array panelTextRows[8] = {
    " ",
    " ",
    " ",
    "    |----- LEFT DELAY -----| |----- RIGHT DELAY ----|",
    " ",
    " ",
    " ",
    "    |--- RING MOD RATE ----| |---- STEREO PHASE ----|"
}
```

Row 3 is the bottom row of instruction 1's tape, closest to the switches. Row 7 is the same for instruction 2. The underlying principle is **3 characters per switch** — each of the 16 switches gets a 3-char slot. One operand byte = 8 switches × 3 chars = 24 characters. The full row is 3-char mnemonic + 1 space + 24 (op-high) + 1 space + 24 (op-low) = 53 characters. When switches are grouped under a single label, the `|--- LABEL ---|` wrapper fits within those 24 chars.

---

**Mode-per-row: each row names one operator position**

Used by bender. Every row has a short mode name followed by operand labels. The key principle throughout is **3 characters per switch** — each of the 16 switches gets a 3-char slot, so one operand byte (8 switches) occupies 24 characters.

```impala
readonly array panelTextRows[8] = {
    "BIT (S)|--- CLEAR BITS ----| |-------- DELAY -------|",
    "SIN (S)|----- AMOUNT ------| |-------- DELAY -------|",
    "ROT (S)|------ RATE -------| |-------- DELAY -------|",
    "DLY |----- LEFT DELAY -----| |----- RIGHT DELAY ----|",
    "SHARP SHELF  _/  ON = _",
    "SHARP FOLD   \\/  ON = \\",
    "SMOOTH SHELF _/  ON = _",
    "SMOOTH FOLD  \\/  ON = \\"
}
```

Rows 0–2 demonstrate how per-switch labeling works when one switch has a special role. `BIT ` is the 4-char prefix (3-char mnemonic + space). Then `(S)` is the **3-char label for the leftmost (MSB) switch** — the stereo bit. That consumes one switch slot outside the grouped label, leaving 7 switches × 3 chars = 21 chars for `|--- CLEAR BITS ----|`. The op1-low operand gets the full 8 × 3 = 24 chars as `|-------- DELAY -------|`. Total: 4 + 3 + 21 + 1 + 24 = 53.

Row 3 (DLY mode) has no stereo switch, so both operand groups use the full 8 × 3 = 24 chars each: `|----- LEFT DELAY -----|` and `|----- RIGHT DELAY ----|`. Total: 4 + 24 + 1 + 24 = 53.

Rows 4–7 are the instruction 2 waveshaping modes. No column alignment, no pipe groups — just enough text to show the curve shape and what the ON state looks like. The `/` is a plain forward slash. The `\` is a plain backslash — written as `\\` in the Impala source since backslash needs escaping.

---

**Mode-per-row with stacked per-switch labels**

Used by pong. The operator knob selects the base clock division. Each switch has its own function (PAN, VOL, TIM, RAND, RECT), so rather than grouping them under two wide labels, pong assigns 3 characters per switch and stacks four rows to spell out the names vertically.

```impala
readonly array panelTextRows[8] = {
    "1/8                           P  P  V  V  T  T  R  R  ",
    "1/16                          A  A  O  O  I  I  A  E  ",
    "1/32                          N  N  L  L  M  M  N  C  ",
    "1/64 |-------- TAPS --------| \u00c3  \u00c1  \u00c2  \u00c0  \u00c3  \u00c1  D  T  ",
    "/1                            P  P  V  V  T  T  R  R  ",
    "/2                            A  A  O  O  I  I  A  E  ",
    "+1/2                          N  N  L  L  M  M  N  C  ",
    "cont |-------- TAPS --------| \u00c3  \u00c1  \u00c2  \u00c0  \u00c3  \u00c1  D  T  "
}
```

The op1-high switches are all labeled together as `TAPS` using the pipe-group format on row 3 only — rows 0–2 leave that area blank (spaces). The op1-low switches get individual 4-character labels, stacked vertically across all four rows. Reading down each 3-char column slot: P/A/N/< = PAN<, P/A/N/> = PAN>, V/O/L/v = VOLv, V/O/L/^ = VOL^, T/I/M/< = TIM<, T/I/M/> = TIM>, R/A/N/D = RAND, R/E/C/T = RECT. The 4th character of each label is a directional arrow. These are written as C-style unicode escape codes in the Impala string (`\u00c3`, `\u00c1`, `\u00c2`, and `\u00c0`) and rendered by Permut8's custom font as arrow glyphs — see the special characters section below. RAND and RECT just use plain letters D and T.

---

**Plain descriptive text**

Used by beatrick. The firmware cycles through four modes for instruction 1, each doing something completely different to the beat. There's no fixed-column layout — each row just explains what that operator position does in plain English.

```impala
readonly array panelTextRows[8] = {
    "MUTE steps that are off",
    "REPEAT steps that are on before off",
    "SKIP steps that are off",
    "HOLD steps that are on, turn on WRITE PROT when done",
    "ACCENT effect",
    "STUTTER effect",
    "REVERSE effect",
    "TAPE STOP effect"
}
```

No pipe delimiters, no column alignment, no operand labeling. The switches in beatrick don't have fixed individual meanings — they just mark steps — so per-switch labels would be meaningless.

---

**Mixed: mode names, operand context, and visual separators**

Used by fooBar. When different operator positions have different parameter meanings, you need more information on each row. This style mixes mode names, per-switch labels, arrows, and underline characters.

```impala
readonly array panelTextRows[8] = {
    "std  REVERSE     STRETCH",
    "fast \u00c5  CRUSH    \u00c5  PITCH    \u00c3--- Enabled Effects",
    "slow \u00c5  \u00c5  CHOP  \u00c5  \u00c5  SLOW    \u00d3\u00d3\u00d3\u00d3\u00d3\u00d3\u00d3\u00d3\u00d3\u00d3\u00d3\u00d3\u00d3\u00d3\u00d3\u00d3\u00d3\u00d3\u00d3\u00d3\u00d3",
    "rnd  \u00c5  \u00c5  \u00c5 AK47\u00c5  \u00c5  \u00c5 STOP \u00d1  Random Order Seed  \u00d2",
    "16/16",
    "32/16",
    "8/8   \u00d3\u00d3\u00d3\u00d3\u00d3\u00d3\u00d3\u00d3\u00d3\u00d3\u00d3\u00d3\u00d3\u00d3\u00d3\u00d3\u00d3\u00d3\u00d3\u00d3\u00d3\u00d3\u00d3\u00d3\u00d3\u00d3\u00d3\u00d3\u00d3\u00d3\u00d3\u00d3\u00d3\u00d3\u00d3\u00d3\u00d3\u00d3\u00d3\u00d3\u00d3\u00d3\u00d3\u00d3\u00d3",
    "16/8 \u00d1  Gates (prev step off = trigger new effect)  \u00d2"
}
```

Rows 0-3 describe instruction 1 effect modes and the related switches. Rows 4-7 describe instruction 2 gate divisions. The `\u00C5`, `\u00D1`, `\u00D2`, and `\u00D3` characters are rendered by Permut8's custom font, so the source reads like text but the UI gets compact arrows, brackets, and horizontal rules.

---

**Single label spanning both operand groups**

Used by linsub. When both operand bytes form a single 16-bit value, you can span the whole row with one label.

```impala
readonly array panelTextRows[8] = {
    "",
    "SUB |-------- 16-BIT LINEAR SUBTRACT AMOUNT --------|",
    "",
    "",
    "",
    "",
    "",
    ""
}
```

The `|---|` section here spans all 16 switches as one continuous range. Row 1 rather than row 3 is used because linsub is a mod patch (operate1 only) and the label position is chosen to align with the actual switch area.

---

### Common tape mistakes

Avoid tape layouts that compile but stop acting like a physical panel label:

- Do not list all operator modes on one or two rows when the operator knob has four active
  positions. Rows 0-3 should still line up with instruction 1 positions 1-4, and rows 4-7
  with instruction 2 positions 1-4.
- Do not put several mutually exclusive operator modes on one row. Use one row per operator
  position when each position has stable operand meanings.
- Do not repeat identical operand labels on every mode row unless the controls really mean
  the same thing in every mode. Repetition hides the rows that need mode-specific labels.
- Do not use stacked vertical words such as `S I Z E` for ordinary operand labels. Reserve
  stacked per-switch labels for layouts where each switch column has a distinct function,
  as in the pong example.
- Do not write prose descriptions when operand controls have stable meanings. Free-form
  text is useful for step or mode descriptions, but a user still needs to know what the
  high and low operand switches do.

For custom multi-mode firmware with stable operands, start from the mode-per-row pattern:

```text
MOD |------ OPERAND A -----| |------ OPERAND B -----|
```

That is the standard 53-character row: a 3-character mnemonic, one space, a 24-character
operand-high field, one space, and a 24-character operand-low field.

### Permut8 special characters

Permut8 uses a custom font (CustomBBL) that maps code points U+00C0 and up to graphic glyphs. In Impala strings you write them as C-style `\uXXXX` escape codes. The full set is documented in `docs/CustomBBL Extra Characters.png`. Here is the complete table:

| Code   | Glyph | Description                        |
|--------|-------|------------------------------------|
| U+00C0 | ↑     | Up arrow                           |
| U+00C1 | →     | Right arrow                        |
| U+00C2 | ↓     | Down arrow                         |
| U+00C3 | ←     | Left arrow                         |
| U+00C4 | —     | Horizontal dash (mid-height)       |
| U+00C5 | │     | Vertical bar                       |
| U+00C6 | ┌     | Top-left corner (bracket open)     |
| U+00C7 | ┐     | Top-right corner (bracket close)   |
| U+00C8 | ┘     | Bottom-right corner                |
| U+00C9 | └     | Bottom-left corner                 |
| U+00CA | ├     | Left T-junction                    |
| U+00CB | ┬     | Top T-junction                     |
| U+00CC | ┤     | Right T-junction                   |
| U+00CD | ┼     | Cross junction                     |
| U+00CE | ┼     | Cross junction variant             |
| U+00CF | ─     | Full-width horizontal bar          |
| U+00D0 | ─     | Short dash                         |
| U+00D1 | /     | Forward slash                      |
| U+00D2 | \     | Backslash                          |
| U+00D3 | _     | Bottom horizontal bar (underline)  |
| U+00D4 | ─     | Small dash (lower position)        |
| U+00D5 | ·     | Very small mark                    |
| U+00D6 | [     | Left square bracket                |
| U+00D7 | ]     | Right square bracket               |
| U+00D8 | ⊥     | Bottom T-junction                  |
| U+00D9 | ⌐     | Corner piece                       |
| U+00DA | ⌞     | Corner piece variant               |
| U+00E0 | [     | Left bracket variant               |
| U+00E1 | ]     | Right bracket variant              |
| U+00E2 | ═     | Double horizontal bar              |
| U+00E3 | ╪     | Cross with double bar              |
| U+00E4 | ▏     | Thin filled bar                    |
| U+00E5 | ▎     | Medium filled bar                  |
| U+00E6 | ▍     | Wide filled bar                    |
| U+00E7 | [     | Bracket (heavier weight)           |
| U+00E8 | ]     | Bracket (heavier weight)           |
| U+00E9 | □     | Hollow rectangle                   |
| U+00EA | ■     | Filled rectangle                   |
| U+00EB | ╲     | Diagonal stroke (lower-right)      |
| U+00EC | ╱     | Diagonal stroke (upper-right)      |
| U+00ED | ∧     | Two diagonals meeting at top       |
| U+00EE | ╱     | Diagonal slash variant             |

The bracket characters (U+00C6/C7, U+00C8/C9) are used in pairs to frame labels. The repeating bar characters (U+00CF, U+00D3) are used for decorative horizontal lines; see `trancelvania_code.impala` and `fooBar_code.impala` for current examples.

### Verifying column-aligned rows

When using the fixed 4+24+1+24 = 53-character format, check your row lengths:

```sh
python3 -c "print(len('    |----- LEFT DELAY -----| |----- RIGHT DELAY ----|'))"
```

Free-form rows like beatrick's have no length requirement.

---

## IVG Sticker

The sticker appears in the top-right slot of the Permut8 UI, rendered from a plain-text IVG file.

Start every sticker with:
```
format IVG-1 requires:IMPD-1;
bounds 0,0,100,40
```

The canvas is 100 × 40 units. Use `IVG-1` — Permut8 doesn't need `IVG-2`.

Permut8's sticker renderer ships no fonts. The IVG `TEXT` and `font` instructions are useful in `IVG2PNG` when external fonts are available, but do not rely on them for artwork that must appear inside the plug-in. Current example stickers draw wordmarks as `PATH` outlines or simple shapes for this reason.

### The tape shows through

Transparent areas reveal the Permut8 tape background (amber/tan paper). This is intentional and how the current sticker examples work: the ringmod diodes, bender logo, and bitbox logo all sit on the tape with tape visible around them. Don't fill the whole canvas dark just to get rid of the amber; that gives you a rectangle instead of a sticker.

Test against the tape colour:
```sh
references/permut8-firmwares-sdk/tools/bin/IVG2PNG --background "#b8a888" my_logo.ivg preview.png
```

### Alpha colours

Six-digit `#RRGGBB` is opaque. Eight-digit is pre-multiplied alpha in `#AARRGGBB` order. The renderer rejects colours where any channel exceeds the alpha byte — R, G, B must each be ≤ A. So `#80ff0000` is invalid (R=0xff > A=0x80). The correct pre-multiplied red at 50% opacity is `#80800000`.

To compute: multiply each channel by the alpha fraction. For `#ff7733` at 40% opacity (A=0x66):
```
R = 0xff × 0.4 ≈ 0x66,  G = 0x77 × 0.4 ≈ 0x30,  B = 0x33 × 0.4 ≈ 0x14
→ #66663014
```

### ImpD things to watch out for

The ternary `{$x ? a : b}` requires an actual boolean — it won't accept 0 or 1 as integers. Use `if` blocks when branching on integer values:
```
if {$x == 1} [fill #ff7733]
if {$x == 0} [fill #1a2030]
```

Gradient fills on shapes work fine. Gradient pens on paths are unreliable — use a thin filled rect as a workaround for gradient lines.

---

## About Text

Clicking the sticker opens the built-in console and prints the about text. The console is 25 rows × 80 columns, but 4 rows are consumed by overhead (the command, blank before, blank after, `sys>` prompt), leaving **21 rows** for content. Lines over 80 characters wrap and cost an extra row.

Check before packaging:
```sh
awk 'END{print NR" lines"} {if(length>80) print "LINE "NR" TOO LONG ("length")"}' about.txt
```

### Approaches — with full examples

---

**Short prose — just describe what it does**

RingMod keeps it simple: a few sentences, no mode list, no tips. Works for firmware that's straightforward enough to understand from the tape.

```
RingMod Permut8 Firmware V1.0 (C)2012-2014 NuEdge Development.

A basic delay with a ring / amplitude modulator. Can run freely or tempo synced.
Right channel phase may be offset for a simple stereo effect.
```

---

**Prose with a mode list**

Beatrick has four instruction 1 modes and four instruction 2 effects. The about names the groups, explains the special HOLD behavior, and gives one operational tip.

```
Beatrick Permut8 Firmware V1.1 (C)2012-2014 NuEdge Development.

This firmware transforms beats in real-time and is designed to be used with
tempo sync turned on.

Instruction 1 offers a choice of four different modes for rearranging the
beat. The HOLD mode is special. It can record and hold slices of incoming
audio so that you can splice together new beats from different sources.
Remember to turn on the WRITE PROTECT switch when you are finished. Otherwise
the spliced beat will be reset when you reload the project in your DAW.

Instruction 2 offers a selection of real-time effects that will be applied to
steps that are turned on.

Tip: right-click the memory lane to bounce the result to a WAV file.
```

---

**Mode list + ASCII art**

Bender has four instruction 1 modes with different parameter meanings, and instruction 2 is a waveshaping function. The ASCII art showing neutral/shelf/fold shapes is more useful than words for explaining what the switches do.

```
Bender Permut8 Firmware V1.0 (C)2014 NuEdge Development.

Bender is a waveshaping distortion tool.

Instruction 1 offers four different pre-shaping options:

  BIT - clears individual bits from the incoming signal
  SIN - scales and applies a sine function to the incoming signal
  ROT - slides the signal up & down (use to add motion to Instruction 2)
  DLY - delay left & right channel independently

Many of the above have a stereo (S) option as well.

Instruction 2 lets you design your waveshaping function. Think of a neutral
shaper as a diagonal line where output = input. Turn bits on to bend this line
in different ways depending on the chosen operator and input level. E.g:

     /           /           /
    /       ____/       /\  /
   /       /           /  \/
  /       /           /

Neutral    Shelf        Fold
```

---

**Per-switch reference**

Pong's about gives a prose overview at the top and then lists what each switch abbreviation means. The tape already shows the abbreviated labels; the about explains them in full.

```
Pong Permut8 Firmware V1.0 (C)2014 NuEdge Development.

Pong is a multi-tap delay. Operator 1 chooses the base division for the delay
(1/8 to 1/64). The actual delay rate will also depend on CLOCK FREQ.

Instruction 2 provides another delay in parallel. You can set its rate in
relation to Instruction 1 (/1 or /2) or offset by 1/2 step or have it continue
after the last step of Instruction 1 (does not work in 1/8 mode).

TAPS - Turn on individual delay steps with these bits.
PAN< - Boosts left output.
PAN> - Boosts right output.
VOLv - Decreases volume for each step.
VOL^ - Increases volume for each step.
TIM< - Increases rate for each step (bouncing ball effect).
TIM> - Decreases rate for each step.
RAND - Offsets the steps by a small random amount.
RECT - Runs audio through a rectifier (cheap pitch shifter) effect.
```

---

**Plain character explanation**

BitBox uses prose rather than a detailed switch table because the firmware is intentionally simple. The about describes the character of the firmware, the step layout, and the audio behavior that would not fit cleanly on the tape.

```
BitBox Permut8 Firmware V1.1 (C)2014-2020 NuEdge Development.

BitBox is a silly little drum machine firmware for Permut8. Perhaps you are
wondering why make a drum machine software for an effect processor? The only
answer I have to that question is "because I could".

BitBox is very basic, monophonic and sounds very bad. You have 16 steps only
(per program). Instruction 1 is bass drum. Instruction 2 is hi-hat, unless
the step is also on for Instruction 1 in which case you'll hear a snare instead.

There are four different bass drums and four different combinations of hi-hats
and snares. They all sound bad.

Incoming audio is mixed in and "volume pumped" to each drum trigger (as if
using a side-chained compressor). This is actually somewhat useful.
```

---

### General advice

Write for someone who just loaded the firmware for the first time and is staring at a wall of unlabelled knobs. The tape handles the quick reference; the about can explain the non-obvious things — operational quirks, recommended settings, what combinations work well, anything that wouldn't fit on the tape.

Use the firmware's own mode names throughout — the names that appear on the tape — not the underlying Permut8 operator names. If the tape says BIT, SIN, ROT, DLY, the about says BIT, SIN, ROT, DLY.
