# Example Selection

Use examples as implementation references, not as generic templates.

- Start from [ringmod_code.impala](../../examples/Firmwares/ringmod_code.impala) for compact
  full-patch DSP that processes `global signal[2]`, uses `yield()`, reads/writes delay
  memory, and has simple panel text.
- Start from [linSubMod_code.impala](../../examples/Firmwares/linSubMod_code.impala) for a compact
  mod patch that works through `global positions[2]`.
- Start from [bender_code.impala](../../examples/Firmwares/bender_code.impala) for
  mode-per-row panel text, multiple operator modes, and explanatory about text.
- Start from [pong_code.impala](../../examples/Firmwares/pong_code.impala) for stacked
  per-switch labels and multi-tap delay behavior.
- Start from [beatrick_code.impala](../../examples/Firmwares/beatrick_code.impala) for
  plain descriptive panel text and step-oriented behavior.
- For modulated delays such as chorus, flanger, vibrato, and pitch effects, write the input
  to memory each sample and read it back from an LFO-modulated fractional delay. Use the
  fractional-delay note in the Firmware API `read()` section. Interpolate both the LFO/table
  lookup and the delay-line read to avoid stepping or resampling noise. Output fully wet and
  let the host `MIX` and feedback controls handle blend and resonance.
- Use [examples/screenshots](../../examples/screenshots) when checking visual expectations for
  stickers and bank examples.
- Use [Impala Snippets.txt](../../examples/Firmwares/Impala%20Snippets.txt) when a firmware
  needs reusable tables or helper routines, such as Permut8-style exponential tables or
  string/numeric conversion. Copy only the needed snippet into the firmware source; Impala
  has no source include mechanism.

When adapting an example:

- Preserve the firmware shape unless the user's request clearly calls for a full patch vs mod
  patch change.
- Keep source and compiled code consistently named. When a firmware also has logo or about
  assets, keep those names aligned with the source prefix.
- Recompile Impala and regenerate the bank after changes.
- Validate the about text and sticker assets when touched.
