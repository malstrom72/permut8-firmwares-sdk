# Permut8 Firmware API

This document describes the host API exposed to Permut8 firmware code running on the GAZL virtual machine. It is written for firmware authors using Impala, the C-like language that compiles to GAZL assembly.

Permut8 firmwares are not native plug-ins. They are sandboxed GAZL programs loaded by Permut8 to extend or replace the signal processing code. The host provides a small set of native functions, constants, globals, and callback entry points.

For the full documentation map, see [Documentation Index](README.md). For the compile/package/load workflow, see [Validation](Validation.md).

## Project-State Persistence

Permut8 saves the actual firmware code with the DAW project state. When a project is reopened, the same GAZL code is restored with the Permut8 instance that used it. A user does not need to reinstall the original firmware bank, keep the same external source file around, or track which version of a firmware was used for that project.

This is a central part of the Permut8 firmware architecture:

- `.p8bank` files are the normal distribution and loading format for end users.
- Once loaded into a Permut8 instance and saved in a DAW project, the firmware code becomes part of that instance's saved state.
- Reloading the DAW project restores the embedded code, not merely a reference to a firmware file on disk.
- Firmware authors should still version source code and banks normally, but old projects should keep using the exact code that was present when they were saved.

The tradeoff is that the code runs in the GAZL virtual machine rather than as native machine code, so CPU cost is higher than equivalent native DSP.

The examples in `examples/Firmwares/` are the source of truth for working firmware patterns. Start with `ringmod_code.impala` for a compact full-patch example and `linSubMod_code.impala` for a mod-patch example. The RingMod path has been verified by compiling Impala to GAZL, generating a `.p8bank`, and loading that bank in Permut8. For the edit/compile/load loop, see [Compiling and Loading Firmwares](Compiling%20and%20Loading%20Firmwares.md); for bank generation, see [Creating P8Bank Files](Creating%20P8Bank%20Files.md).

## Patch Types

Permut8 supports two practical firmware shapes:

- **Full patches** replace the virtual DSP and process 12-bit stereo audio samples directly. Full patches define `global array signal[2]` and implement `process()`.
- **Mod patches** replace one or more built-in operators. They process stereo delay-line read positions instead of audio samples. Mod patches define `global array positions[2]` and implement `operate1()`, `operate2()`, or both.

Full patches and mod patches can share helper code, panel text, parameters, LEDs, and initialization/update callbacks, but their audio entry points and required globals are different.

## Signal Chain Around a Patch

A firmware patch does not run in isolation. Permut8 wraps the virtual DSP in its analog controls, feedback loop, filter, delay memory, and dry/wet mixer. Knowing where the patch sits prevents duplicated work in firmware.

```text
dry input
   |
INPUT LEVEL
   |
feedback sum <------------------------------- feedback return
   |                                          FEEDBACK AMOUNT,
   |                                          FLIP L/R, INVERT
soft clipper -> LIMITER -> 12-bit conversion
   |
YOUR PATCH
   |  full patch: process() on signal[0..1]
   |  mod patch: operate1()/operate2() on read positions
   v
wet output -> OUTPUT LEVEL / soft clipper
   |                         |
   |                         +--------------> feedback tap
   v
MIX, latency-compensated dry/wet blend -> output
```

Important consequences for firmware authors:

- `signal[0]` and `signal[1]` are not the raw host input. They arrive after input gain, the feedback sum, input saturation/limiting, and 12-bit conversion.
- The value a full patch writes back to `signal[0..1]` is the wet signal. The host applies output level, feeds that result back according to the feedback controls, and blends it with the dry input through `MIX`.
- The analog filter is host-side. `FILTER PLACEMENT` chooses `IN` before the soft clipper/limiter but inside the feedback loop, `FB` on the feedback return only, `OUT` on the final output and feedback tap, or `OFF`.
- In normal firmware, keep the patch fully wet and let `MIX` handle dry/wet balance. Permut8's mix control compensates the variable clock latency in a way a firmware-local blend cannot.
- Do not rebuild feedback, filtering, or saturation unless they are intentionally part of the firmware's own sound. The front-panel controls already provide those functions around the patch.
- Delay memory is one full 16-bit clock cycle of 12-bit stereo frames, described in the user guide as 128 kilowords. `write(clock, ...)` writes at the current head, `read(clock - d, ...)` reads `d` frames back, and both wrap.

## Required Format Constant

Every current Permut8 1.1 firmware should define:

```impala
const int PRAWN_FIRMWARE_PATCH_FORMAT = 2
```

Older sources may contain format `1`. New firmware should use format `2` unless an old compatibility target explicitly requires otherwise.

## Panel Text

Firmware can replace the standard Permut8 screen print by defining eight text rows:

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

Rows use fixed character positions. The traditional layout is a three-character instruction mnemonic, one space, three characters per switch for the first operand group, one space, then the same for the second operand group. A blank or single-space row leaves no tape text on that row.

The row pointers do not need to point at constant data, but after `init()` returns the pointed-to text should not change.

## Native Functions

Permut8 provides these native functions to firmware code:

```impala
extern native abort
extern native trace
extern native yield
extern native write
extern native read
```

### `abort()`

Stops the firmware and restores normal Permut8 operation. Use this for fatal initialization or configuration errors.

### `trace(pointer string)`

Writes a null-terminated string to the Prawn console and to standard output on macOS or DebugView on Windows. In Permut8, tracing is enabled when loading firmware from the console and disabled when firmware is loaded from a `.p8bank`.

### `yield()`

Suspends the firmware and returns control to the Permut8 audio engine. When the next sample is ready, `yield()` returns and execution continues from exactly where it left off, with all local variables still live on the stack.

This turns `process()` into a coroutine. Instead of being called and returning once per sample, a firmware using `yield()` runs as an infinite loop that suspends between samples. The practical reason to do this is performance: local variables are fast in GAZL, globals are slow. Without `yield()`, any state carried across samples must live in globals. With `yield()`, working state can live in locals for the lifetime of the firmware.

The typical pattern, used in `ringmod_code.impala`, is an outer `loop {}` containing a batch-sized `for` loop, with `yield()` at the end of each iteration. Globals are copied to locals once per batch rather than once per sample, and the inner loop works entirely in fast local storage.

### `write(int offset, int frameCount, pointer values)`

Writes `frameCount` 12-bit stereo frames to the delay-line memory at `offset`. Values are interleaved stereo samples. Reads and writes wrap automatically to the delay-line size.

`offset` is an absolute delay-line position. Use `global clock` as the current write cursor. For example, `write(clock, 1, global signal)` writes the current sample at the write head, and `read(clock - delay, 1, buf)` reads from `delay` samples back.

To build a delay, write the input at `clock` each sample and read it back from `clock - delay`. See the fractional-delay note under `read()` when the delay is modulated or needs sub-sample resolution.

### `read(int offset, int frameCount, pointer values)`

Reads `frameCount` 12-bit stereo frames from the delay-line memory at `offset` into an interleaved stereo buffer. Reads and writes wrap automatically to the delay-line size.

`offset` is an absolute delay-line position — see `write()` above for the `clock`-relative pattern.

`offset` is an integer sample position. `read()` does not interpolate. For a smoothly
modulated or fractional delay, keep the delay as fixed point, read the two neighbouring
frames, and interpolate in firmware. This example uses a 16.16 fixed-point delay:

```impala
di = d >>> 16;                       // integer delay in samples
fr = d & 0xffff;                     // fractional part, 0..65535
read(clock - di - 1, 2, buf);        // buf = [Lold,Rold,Lnew,Rnew]
outL = (int) buf[2] + ((((int) buf[0] - (int) buf[2]) * fr) >> 16);
outR = (int) buf[3] + ((((int) buf[1] - (int) buf[3]) * fr) >> 16);
```

Two-point linear interpolation is usually enough for gentle chorus, flanger, vibrato, and
similar modulation. Deeper or faster modulation may need four frames and a cubic or Hermite
interpolator to reduce resampling artifacts. `beatrick_code.impala` shows the two-frame
pattern, and `pong_code.impala` shows batched multi-frame delay reads.

## Host Constants

The host defines these constants at load time:

```impala
const int DEBUG

const int OPERATOR_1_NOP
const int OPERATOR_1_AND
const int OPERATOR_1_MUL
const int OPERATOR_1_OSC
const int OPERATOR_1_RND
const int OPERATOR_1_COUNT

const int OPERATOR_2_NOP
const int OPERATOR_2_OR
const int OPERATOR_2_XOR
const int OPERATOR_2_MSK
const int OPERATOR_2_SUB
const int OPERATOR_2_COUNT

const int SWITCHES_SYNC_MASK
const int SWITCHES_TRIPLET_MASK
const int SWITCHES_DOTTED_MASK
const int SWITCHES_WRITE_PROTECT_MASK
const int SWITCHES_REVERSE_MASK

const int CLOCK_FREQ_PARAM_INDEX
const int SWITCHES_PARAM_INDEX
const int OPERATOR_1_PARAM_INDEX
const int OPERAND_1_HIGH_PARAM_INDEX
const int OPERAND_1_LOW_PARAM_INDEX
const int OPERATOR_2_PARAM_INDEX
const int OPERAND_2_HIGH_PARAM_INDEX
const int OPERAND_2_LOW_PARAM_INDEX
const int PARAM_COUNT

const int POSITION_INT_BITS
const int POSITION_FRACT_BITS
const int HOST_POSITION_PPQ
```

`DEBUG` is non-zero when asserts and tracing are enabled. `HOST_POSITION_PPQ` is the host song-position resolution, normally 1920 pulses per quarter note.

The operator constants describe the stock operator selections currently exposed through `params`. Custom firmware may reinterpret operators and operands, but reusing these constants keeps code readable when the firmware follows Permut8's front-panel model.

## Host Parameters

Declare the parameter array when the firmware needs front-panel values:

```impala
global array params[PARAM_COUNT]
```

`params` contains integers updated by Permut8 whenever exposed parameters change:

- `params[CLOCK_FREQ_PARAM_INDEX]`: clock frequency / sample rate rounded to integer Hz.
- `params[SWITCHES_PARAM_INDEX]`: bit mask for sync, triplet, dotted, write-protect, and reverse switches.
- `params[OPERATOR_1_PARAM_INDEX]`: operator 1 selection.
- `params[OPERAND_1_HIGH_PARAM_INDEX]`: operand 1 high byte, 0 to 255.
- `params[OPERAND_1_LOW_PARAM_INDEX]`: operand 1 low byte, 0 to 255.
- `params[OPERATOR_2_PARAM_INDEX]`: operator 2 selection.
- `params[OPERAND_2_HIGH_PARAM_INDEX]`: operand 2 high byte, 0 to 255.
- `params[OPERAND_2_LOW_PARAM_INDEX]`: operand 2 low byte, 0 to 255.

For common operand-to-value mappings used by the examples and stock-style firmwares, see [Operand Scaling Conventions](Operand%20Scaling%20Conventions.md).

Use the switch masks like this:

```impala
if (((int) global params[SWITCHES_PARAM_INDEX] & SWITCHES_REVERSE_MASK) != 0) {
	// reverse mode is enabled
}
```

## Optional Host Globals

Declare only the globals your firmware uses.

### `global int clock`

`clock` increments between every `process()` call, or decrements in reverse mode. It has a 16-bit cycle from `0` to `65535`. If tempo sync is enabled, `clock` is the absolute position within the chosen time division.

The 16-bit clock cycle equals the delay-line length, so `clock - d` addresses up to a full memory cycle of delay.

### `global int hostPosition`

Host song position in PPQ notation, scaled by the chosen time division. It is `0` when sync is off and `-1` when the host is not currently playing. `HOST_POSITION_PPQ` gives the PPQ base.

### `global array displayLEDs[4]`

Four 8-bit masks controlling the visualizer LEDs below the operand switches. The order is operand 1 high, operand 1 low, operand 2 high, operand 2 low.

### `global int instance`

A session-unique number for the plug-in instance. It is valid after initialization and does not change. Use it to seed random generators when different instances should behave differently.

### `readonly int clockFreqLimit`

Limits the maximum clock frequency used by the firmware. Permut8 can normally run as fast as 352.8 kHz, but GAZL code is more CPU-intensive than native DSP code. Permut8 reads this global once after calling `init()`. A value of `0` or an omitted declaration means no firmware-specific limit.

```impala
readonly int clockFreqLimit = 132300
```

### `global array config[...]`

Declaring `config` lets the user enter a configuration string for the firmware. This can be done by clicking the firmware tape on the main GUI or by entering a string after the firmware name when patching via the console. Permut8 fills this array before calling `init()`. The array can have any practical size.

```impala
global array config[100]
```

### `global pointer configText`

Defines custom description text for the configuration dialog shown when clicking the firmware tape.

```impala
global pointer configText
```

## Tempo Sync

The sync switch is reported through `params[SWITCHES_PARAM_INDEX]`:

- `SWITCHES_SYNC_MASK` is set for any synced mode.
- `SWITCHES_DOTTED_MASK` is set for dotted sync.
- `SWITCHES_TRIPLET_MASK` is set for triplet sync.
- Standard sync is synced with neither dotted nor triplet set.

In synced modes, `CLOCK FREQ` selects the duration of one full memory cycle. The current
Permut8 sync rates are:

| Mode | Memory-cycle lengths |
|---|---|
| Standard | `8/1`, `4/1`, `2/1`, `1/1`, `1/2`, `1/4`, `1/8` |
| Dotted | `12/1`, `6/1`, `3/1`, `3/2`, `3/4`, `3/8`, `3/16` |
| Triplet | `16/3`, `8/3`, `4/3`, `2/3`, `1/3`, `1/6`, `1/12` |

These values are note lengths, expressed as whole notes per memory cycle. `1/1` is one
whole note, or four quarter notes. With `HOST_POSITION_PPQ` normally `1920`, one `1/1`
cycle is `HOST_POSITION_PPQ * 4` host pulses before Permut8's sync scaling is applied.

`hostPosition` is scaled by the active sync ratio so that one selected memory cycle maps to
`HOST_POSITION_PPQ * 4` pulses from the firmware's point of view. This makes the common
cross-cycle index independent of the selected sync rate:

```impala
cycle = global hostPosition / (HOST_POSITION_PPQ * 4);
```

Use `global clock` for phase within the current memory cycle: it always covers the cycle as
`0..65535`. Use `hostPosition` only when the firmware needs to know which cycle it is in, or
when a pattern must evolve across cycles. `hostPosition` is `0` when sync is off and `-1`
when the transport is not playing, so synced timeline logic should handle both cases.

Firmware does not receive a separate host time-signature value. Write sync logic in terms of
memory-cycle note lengths and PPQ pulses, and verify any bar-specific behavior in a real host.

## Full-Patch Globals

Full patches must declare:

```impala
global array signal[2]
```

`signal[0]` and `signal[1]` contain the left and right 12-bit input samples, from `-2047` to `2047`. Replace them with the output samples before returning from `process()` or before yielding to the host.

## Mod-Patch Globals

Mod patches must declare:

```impala
global array positions[2]
```

`positions[0]` and `positions[1]` are the left and right memory positions to be processed by `operate1()` or `operate2()`. Positions use fixed-point notation with `POSITION_FRACT_BITS` fractional bits, normally 4 bits for linear interpolation. With the current 16 integer bits and 4 fractional bits, the full range is `0x00000` to `0xFFFFF`. Values outside the range wrap.

## Update Filtering

If a firmware defines `update()`, Permut8 calls it when exposed parameters change. A readonly `updateMask` can restrict which parameters trigger `update()`:

```impala
readonly int updateMask =
		(1 << OPERAND_1_HIGH_PARAM_INDEX) | (1 << OPERAND_1_LOW_PARAM_INDEX)
		| (1 << OPERAND_2_HIGH_PARAM_INDEX) | (1 << OPERAND_2_LOW_PARAM_INDEX)
```

Use this to avoid recalculating tables for changes that do not matter to the firmware. For example, use `~(1 << CLOCK_FREQ_PARAM_INDEX)` to prevent calls caused only by clock-frequency changes.

## Entry Points

Permut8 discovers firmware behavior by looking for named functions.

### `init()`

Optional. Called when the firmware is loaded, after host globals such as `config` are prepared. Use it to initialize tables, seeds, delay memory, configuration-dependent state, and display text. If initialization cannot continue, call `abort()`.

### `reset()`

Optional. Called when the user flips the RESET switch, when the host requests a plug-in reset, and once automatically after `init()` and the first call to `update()`. Use it to reset transient DSP state — things that should return to a known value without rebuilding static tables like lookup tables or configuration-derived data.

### `update()`

Optional. Called by the host when parameters selected by `updateMask` change — typically no more frequently than every 136–137 samples. Also called once initially by the host before the first `reset()`. Use it to precompute values derived from operators, operands, switch states, and clock frequency.

### `process()`

Required for full patches. It processes one stereo sample frame using `global signal[2]`.

```impala
function process()
{
	// Read input from global signal[0..1].
	// Write output back to global signal[0..1].
}
```

A full patch may call `read()` and `write()` to use Permut8's delay memory. It may call `yield()` to suspend processing until the next sample while preserving function-local state.

### `operate1()` and `operate2()`

Required for mod patches, depending on which built-in operator slot the firmware replaces. They process `global positions[2]`.

Return non-zero if the firmware processed the positions. Return zero to pass processing on to the original Permut8 operator.

Some older examples use an argument on `operate1`, reflecting earlier experimentation. For new firmware, follow the current examples that operate on `global positions[2]` and keep the signature consistent with the target slot.

## Performance

GAZL global variable accesses are significantly slower than local variable accesses. Audio-rate code should minimize how often it touches globals directly.

### Integer vs float

Both integer and floating-point arithmetic are practical inside `process()`. GAZL values are
single VM words, and fixed-point integer code can cost extra shifts, masks, scaling, and
overflow checks. Do not choose integer fixed point only because it seems lower level.

Use integer and fixed-point math when the quantized behavior is part of the sound or when you
need exact bit operations. Use float when it makes the expression simpler, especially for
LFOs, envelopes, interpolation coefficients, and other scaling math. The usual audio-rate
costs to avoid are repeated global access and expensive functions inside the sample loop; keep
using locals and precomputed tables either way.

GAZL integers are one VM word, normally 32-bit signed, with no 64-bit intermediate for wide
products. Float can be the more robust choice for scaling that would otherwise overflow.

### Copy globals to locals

Use Impala's `copy` statement to transfer an entire global array into a local array in one operation, then work exclusively with the local copy:

```impala
function update()
locals array params[PARAM_COUNT]
{
    copy (PARAM_COUNT from global params to params)
    // Work with local params — fast.
    global delayL = (int) global EIGHT_BIT_EXP_TABLE[(int) params[OPERAND_1_HIGH_PARAM_INDEX]];
}
```

For scalar globals read inside a hot loop, copy them to locals before the loop:

```impala
function process()
locals int rate, int delayL
{
    loop {
        rate = global rate;
        delayL = global delayL;
        // Inner loop uses local rate and delayL — no global reads per sample.
        for (i = 0 to BATCH_SIZE) {
            // ...
            yield();
        }
    }
}
```

### Batch processing with `yield()`

Rather than re-reading globals on every sample, use `yield()` to structure `process()` as a coroutine with an outer loop and a fixed-size inner batch loop. Globals are read once per batch; locals carry state across all samples in the batch:

```impala
function process()
locals int i, int rate, int delayL
{
    loop {
        rate   = global rate;    // Read globals once per batch.
        delayL = global delayL;
        for (i = 0 to BATCH_SIZE) {
            // ... DSP using rate and delayL ...
            yield();             // Suspend until next sample; locals survive.
        }
    }
}
```

`BATCH_SIZE` is a firmware constant. `ringmod_code.impala` uses 77. Larger batches amortize the global-read cost further but increase the lag before parameter changes take effect.

### Precompute in `update()`

Anything derived from params — table lookups, frequency calculations, fixed-point scaling — should be computed in `update()` and stored as globals. `process()` then reads only the precomputed result, not the raw params:

```impala
global int rate        // precomputed from operand
global int delayL      // precomputed from operand

function update()
locals array params[PARAM_COUNT]
{
    copy (PARAM_COUNT from global params to params)
    global rate   = (int) global EXP_TABLE[(int) params[OPERAND_2_HIGH_PARAM_INDEX]];
    global delayL = (int) global EXP_TABLE[(int) params[OPERAND_1_HIGH_PARAM_INDEX]];
}
```

Use `updateMask` to suppress `update()` calls for parameters the firmware ignores, reducing unnecessary recalculation.

### Lookup tables

Avoid computing transcendental functions (sine, cosine, exponent) at audio rate. Precompute them into `readonly` or `global` arrays during `init()` and index into the table in `process()`. `ringmod_code.impala` demonstrates this with a 4096-entry cosine table with linear interpolation between entries.

## Practical Authoring Rules

- Prefer Impala for new firmware. Raw GAZL is possible but harder to maintain.
- Declare only host globals that are actually used.
- Keep audio-rate work bounded. Avoid loops whose iteration count depends on user input unless the maximum is small and obvious.
- Precompute parameter-derived tables in `update()` rather than in `process()`.
- Use `clockFreqLimit` for CPU-heavy firmware.
- Use `displayLEDs` to give useful feedback for sequencers, meters, selected steps, or active operands.
- Keep `panelTextRows` stable after `init()`.
- Treat `.p8bank` loading as release behavior and console loading as development/debug behavior.

## Minimal Full-Patch Skeleton

```impala
const int PRAWN_FIRMWARE_PATCH_FORMAT = 2

readonly array panelTextRows[8] = {
	" ",
	" ",
	" ",
	"    |------ AMOUNT -------| |------ COLOR --------|",
	" ",
	" ",
	" ",
	" "
}

extern native abort
extern native trace
extern native yield
extern native write
extern native read

const int DEBUG
const int CLOCK_FREQ_PARAM_INDEX
const int SWITCHES_PARAM_INDEX
const int OPERATOR_1_PARAM_INDEX
const int OPERAND_1_HIGH_PARAM_INDEX
const int OPERAND_1_LOW_PARAM_INDEX
const int OPERATOR_2_PARAM_INDEX
const int OPERAND_2_HIGH_PARAM_INDEX
const int OPERAND_2_LOW_PARAM_INDEX
const int PARAM_COUNT

global array params[PARAM_COUNT]
global array displayLEDs[4]
global array signal[2]

readonly int clockFreqLimit = 132300

function update()
{
	global displayLEDs[0] = (int) global params[OPERAND_1_HIGH_PARAM_INDEX];
	global displayLEDs[1] = (int) global params[OPERAND_1_LOW_PARAM_INDEX];
	global displayLEDs[2] = (int) global params[OPERAND_2_HIGH_PARAM_INDEX];
	global displayLEDs[3] = (int) global params[OPERAND_2_LOW_PARAM_INDEX];
}

function process()
locals int l, int r
{
	l = (int) global signal[0];
	r = (int) global signal[1];

	// Replace with real DSP.
	global signal[0] = l;
	global signal[1] = r;
}
```

## Minimal Mod-Patch Skeleton

```impala
const int PRAWN_FIRMWARE_PATCH_FORMAT = 2

readonly array panelTextRows[8] = {
	" ",
	" ",
	" ",
	"    |---- POSITION MOD ---| |---------------------|",
	" ",
	" ",
	" ",
	" "
}

extern native abort
extern native trace

const int OPERAND_1_HIGH_PARAM_INDEX
const int OPERAND_1_LOW_PARAM_INDEX
const int PARAM_COUNT
const int POSITION_INT_BITS
const int POSITION_FRACT_BITS

global array params[PARAM_COUNT]
global array displayLEDs[4]
global array positions[2]

function update()
{
	global displayLEDs[0] = (int) global params[OPERAND_1_HIGH_PARAM_INDEX];
	global displayLEDs[1] = (int) global params[OPERAND_1_LOW_PARAM_INDEX];
}

function operate1()
locals int offset
{
	offset = ((int) global params[OPERAND_1_HIGH_PARAM_INDEX] << 8)
			| ((int) global params[OPERAND_1_LOW_PARAM_INDEX]);
	offset = offset << POSITION_FRACT_BITS;

	global positions[0] = (int) global positions[0] + offset;
	global positions[1] = (int) global positions[1] + offset;
	return 1;
}
```
