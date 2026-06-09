# Validation

Use the repository validation guide as the canonical checklist:

[../../docs/Validation.md](../../docs/Validation.md)

Expected agent practice:

- Compile touched `.impala` files to `.gazl` whenever the local toolchain can run.
- Generate or regenerate the `.p8bank` with `tools/createP8Bank.pika`.
- For user-facing banks, check that program slots are intentional and preferably include
  named example programs that exercise the firmware's important behaviors.
- Check about text line count and 80-column width.
- Check panel text as a control surface: row lengths for fixed layouts, operator-position
  alignment, visible operand meanings, and avoidance of stacked labels unless switches are
  truly per-column controls.
- Render static `.ivg` stickers with `references/permut8-firmwares-sdk/tools/bin/IVG2PNG`
  when the renderer is available.
- Treat a successful compile/package/render pass as structural validation, not proof of
  runtime DSP behavior inside Permut8.
- When plugin access is not available, say that the final load test in Permut8 was not run.

Do not claim that firmware was tested in Permut8 unless it was actually loaded there.

For direct console development, the example firmware folder includes
`Compile Loop OS X.command` and `Compile Loop Windows.bat`. Those scripts regenerate
matching `.gazl` files when `.impala` sources change. After a firmware has been loaded once
with the Permut8 console patch tool, the patch tool reloads the active firmware when the
watched `.gazl` changes, so the compile loop provides practical hot reload while editing.
