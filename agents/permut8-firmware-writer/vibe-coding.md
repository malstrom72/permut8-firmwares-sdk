# Vibe-Coding Permut8 Firmwares

This guide is for using an AI coding assistant with the Permut8 Firmwares SDK. The SDK
should be treated as the source of truth for documentation, examples, tools, language
references, and validation steps.

## Starter Prompt For Codex, Claude, Or ChatGPT

Copy this into a fresh agent session to bootstrap a Permut8 firmware project:

```text
I want to build Sonic Charge Permut8 firmwares with this SDK:

https://github.com/malstrom72/permut8-firmwares-sdk

Before writing firmware logic, clone the latest SDK from GitHub into:

references/permut8-firmwares-sdk/

Then read and follow the latest project bootstrap instructions in:

references/permut8-firmwares-sdk/agents/permut8-firmware-writer/instructions.md

Set up the project exactly as those instructions describe, then wait for my
firmware idea.
```

## Recommended Project Layout

Keep your own firmware work in a separate project and use this SDK as a reference:

```text
my-permut8-firmwares/
  AGENTS.md
  references/
    permut8-firmwares-sdk/
```

The assistant should write project firmware files and generated banks outside the SDK,
unless you are deliberately contributing SDK examples.

## Minimal Project `AGENTS.md`

In your project root, add an `AGENTS.md` like this:

```md
# Project Agent Instructions

For Permut8 firmware work, follow:

`references/permut8-firmwares-sdk/agents/permut8-firmware-writer/instructions.md`

Use the SDK checkout as the source of truth for docs, examples, tools, packaging, and
validation.
```

## Choosing Workflow

Use `.p8bank` output for finished user-facing firmware. Use console loading only when the
user wants iterative development and debugging inside Permut8.

## Ask The Assistant To Ground Its Work

Good prompts are explicit about SDK grounding:

```text
Create a Permut8 full-patch firmware. Use the SDK firmware API and examples as source of
truth. Package the result as a .p8bank.
```

```text
Create a Permut8 mod patch. Inspect the closest SDK example first, compile it to GAZL,
generate a bank, and run all available structural validation before finishing.
```

## Validation

For local validation, follow [docs/Validation.md](../../docs/Validation.md). A structural
pass means the source compiles, assets package, and static graphics render where applicable.
It does not prove the firmware was tested inside Permut8.
