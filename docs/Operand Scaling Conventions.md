# Operand Scaling Conventions

Permut8 exposes each operand byte to firmware as a raw value from `0` to `255`:
`OPERAND_n_HIGH` and `OPERAND_n_LOW`. Firmware is responsible for mapping those bytes to
delay times, rates, amounts, or mode-specific values.

The SDK does not require one scaling. These conventions recur in stock-style firmwares and
the examples, so reusing them gives controls a familiar feel. The reusable exponential
tables are collected in `examples/Firmwares/Impala Snippets.txt`; copy the table you need
into your firmware source because Impala has no include system.

| Convention | Mapping | Use for | Source |
|---|---|---|---|
| 8-bit exponential table | byte `0..255` to `0x0000..0xffff`, with fine resolution at low values and coarse resolution at high values | delay time, rate, and other logarithmic-feeling one-byte controls | `EIGHT_BIT_EXP_TABLE` in `Impala Snippets.txt`, `ringmod_code.impala`, `bender_code.impala` |
| 7-bit exponential table | value `0..127` to `0x0000..0x8000`, same style with half the range | split-byte or reduced-range exponential controls | `SEVEN_BIT_EXP_TABLE` in `Impala Snippets.txt` and `ringmod_code.impala` |
| 16-bit linear | `(high << 8) | low` to `0..65535` | exact amounts, fine delay offsets, or controls where every step should have equal weight | `linSubMod_code.impala` |
| MUL-style fixed-point rate | 16-bit rate value where `0x0100` is normal speed, `0x0200` is one octave up, `0x0080` is one octave down, `0x0000` is stopped, and the high bit indicates reverse | playback-rate style behavior modeled after the stock `MUL` operator | Permut8 User Guide, `MUL` |

Use exponential scaling when the ear expects ratios rather than equal steps, especially for
time, pitch, and rate controls with only one byte of resolution. Use 16-bit linear scaling
when a pair of operand bytes should act as one precise value across the whole memory cycle or
amount range.

## Sample-Based vs Time-Based Values

Delay-line offsets are measured in samples, and the effective sample rate is the `CLOCK FREQ`
knob. A fixed sample count changes duration when the user changes clock frequency: it sounds
longer at low clock rates and shorter at high clock rates. That behavior is part of
Permut8's character, but it can surprise authors of chorus, flanger, and vibrato-style
effects.

If a value should stay constant in milliseconds regardless of clock frequency, convert it in
`update()` using `params[CLOCK_FREQ_PARAM_INDEX]`, which is the current clock frequency in Hz:

```impala
samples = ms * clockHz / 1000;
```

Precompute this conversion outside the audio loop.
