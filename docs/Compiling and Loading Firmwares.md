# Compiling and Loading Firmwares

This guide describes the development workflow for compiling Impala firmware sources to GAZL and loading the result directly in Permut8 through the built-in console, without first packaging a `.p8bank`.

For end-user distribution and normal firmware output, use `.p8bank` firmware banks. Direct console loading is a development workflow. See [Creating P8Bank Files](Creating%20P8Bank%20Files.md) for the bank generation path and [Validation](Validation.md) for compile/package/load checks.

## Firmware Code Folder

Permut8's development firmware folder is named exactly:

```text
Permut8 Firmware Code
```

Common locations:

```text
macOS:   /Library/Application Support/Sonic Charge/Permut8 Firmware Code/
Windows: C:\Program Files\Sonic Charge\Permut8 Firmware Code\
```

The development folder should contain:

- the current Impala compiler toolchain
- one or more `*_code.impala` firmware sources
- generated `*_code.gazl` files
- optional `*_logo.ivg` and `*_about.txt` files used by matching firmware names

The firmware-code package uses `PikaCmd`, `impala.pika`, and `impalaCompiler.pika`. The RingMod compile path in this SDK has been verified with that toolchain, and this is the only supported Impala compiler path for this repository.

`PikaCmd` is the command-line runner for PikaScript. The SDK includes PikaCmd source
copied from [malstrom72/PikaScript](https://github.com/malstrom72/PikaScript), plus a
runtime copy of the executable in `examples/Firmwares/`. It is still needed because the
Impala-to-GAZL compiler in the Permut8 firmware folder is itself a PikaScript program:
`PikaCmd` runs `impala.pika`, `impala.pika` loads `impalaCompiler.pika`, and that compiler
emits the `.gazl` text loaded by Permut8.

To verify or rebuild PikaCmd from the bundled source on macOS/Linux:

```sh
cd references/permut8-firmwares-sdk/PikaCmd
bash BuildPikaCmd.sh
```

The build script compiles `PikaCmdAmalgam.cpp` and runs the bundled PikaScript tests.
Modern C++ toolchains may print deprecation warnings for old standard-library helpers;
those warnings do not prevent a successful build.

## Development Folder Linking

The `Permut8 Firmware Code` folder is normally in a system location with limited write access. For quicker round-trips, keep a project-local copy of the entire folder and link Permut8's system folder to it. Copy the current folder into your project first so installed tools and existing firmwares are preserved.

On macOS, the folder is normally:

```text
/Library/Application Support/Sonic Charge/Permut8 Firmware Code/
```

Copy it into your project, move the original aside, then create a symbolic link:

```sh
mkdir -p "/path/to/my-permut8-firmwares"
cp -R "/Library/Application Support/Sonic Charge/Permut8 Firmware Code" \
  "/path/to/my-permut8-firmwares/firmware-code"
sudo mv "/Library/Application Support/Sonic Charge/Permut8 Firmware Code" \
  "/Library/Application Support/Sonic Charge/Permut8 Firmware Code.backup"
sudo ln -s "/path/to/my-permut8-firmwares/firmware-code" \
  "/Library/Application Support/Sonic Charge/Permut8 Firmware Code"
```

On Windows, the common location is:

```text
%PROGRAMFILES%\Sonic Charge\Permut8 Firmware Code
```

Copy it into your project, move the original aside, then create a directory junction:

```bat
xcopy "%PROGRAMFILES%\Sonic Charge\Permut8 Firmware Code" ^
  "C:\path\to\my-permut8-firmwares\firmware-code\" /E /I
ren "%PROGRAMFILES%\Sonic Charge\Permut8 Firmware Code" "Permut8 Firmware Code.backup"
mklink /J "%PROGRAMFILES%\Sonic Charge\Permut8 Firmware Code" ^
  "C:\path\to\my-permut8-firmwares\firmware-code"
```

After linking, firmware files edited in your project-local `firmware-code` directory are the same files Permut8 sees.

## Compile One Firmware

Compile an Impala source file with:

```sh
./PikaCmd impala.pika compile ringmod_code.impala ringmod_code.gazl
```

On Windows:

```bat
PikaCmd impala.pika compile ringmod_code.impala ringmod_code.gazl
```

The generated `.gazl` file is the code format loaded by the Permut8 virtual machine and embedded in `.p8bank` firmware banks. This command was verified by compiling `ringmod_code.impala` to `ringmod_code.gazl`, packaging the result, and loading the generated bank in Permut8.

## Auto-Compile While Editing

The example firmware folder includes compile-loop scripts:

- `examples/Firmwares/Compile Loop OS X.command`
- `examples/Firmwares/Compile Loop Windows.bat`

They watch the current folder and recompile any `.impala` file newer than its matching `.gazl` file.
Run the macOS script by double-clicking it in Finder or launching it from Terminal. Run the
Windows script from the `Permut8 Firmware Code` folder. Both scripts expect `PikaCmd`,
`impala.pika`, and `impalaCompiler.pika` to be in the same folder as the firmware sources.

The macOS loop is essentially:

```sh
for FILE in *.impala; do
	if [ "$FILE" -nt "${FILE%.impala}.gazl" ]; then
		./PikaCmd impala.pika compile "$FILE" "${FILE%.impala}.gazl"
	fi
done
```

Keep the compile loop running while editing. After the firmware has been loaded once from
the Permut8 console, the console `patch` tool watches the loaded `.gazl` file and reloads
the firmware automatically when that file changes. In practice, editing an `.impala` file
gives a hot-reload loop:

1. Save the `.impala` source.
2. The compile-loop script regenerates the matching `.gazl`.
3. The console patch tool notices the changed `.gazl` and reloads the active firmware.

If the compile fails, the old `.gazl` remains the last successfully loaded code. If you
change to a different firmware name, run that patch from the console once so Permut8 starts
watching the new `.gazl`.

## Loading from the Permut8 Console

Permut8 has a built-in terminal / console used for development and hidden firmware features.

Public Sonic Charge forum posts describe the access flow as:

1. Click the Permut8 logotype to open the built-in terminal.
2. Enter `logon`.
3. Enter username `username` and password `password`.
4. Use `run patch` to list or run firmware patches.
5. Run a firmware by name, optionally followed by configuration text.

Example shown publicly for the speech firmware:

```text
run patch
sam hi there!
```

For custom development firmwares, the patch name is normally derived from the firmware files in the firmware folder. For example, a compiled `ringmod_code.gazl` is loaded as the `ringmod` patch, with matching `ringmod_logo.ivg` and `ringmod_about.txt` files used when present.

When loading through the console:

- `DEBUG` is non-zero, so Impala `assert` checks and `trace()` output are enabled.
- Optional configuration text after the firmware name is placed in `global array config[...]` before `init()` is called, if the firmware declares `config`.
- This is the fastest iteration path because it avoids rebuilding a `.p8bank` for every edit.
- When paired with a compile-loop script, the console patch tool reloads the active firmware
  whenever the watched `.gazl` file changes.

When loading through a `.p8bank`:

- `DEBUG` is normally zero.
- Traces and asserts are disabled.
- This is the expected release / user workflow.

## Configuration Strings

Firmware can accept console text or tape-dialog text by declaring:

```impala
global array config[100]
```

Permut8 fills `config` before calling `init()`. The firmware can parse it in `init()` and call `abort()` if the configuration is invalid.

Firmware can provide custom description text for the tape-dialog configuration field with:

```impala
global pointer configText
```

## Saved Project Behavior

After a firmware is loaded into a Permut8 instance and the DAW project is saved, the actual GAZL code is saved with the project state. Reopening the project restores that embedded code. The project does not merely reference the external `.gazl`, `.impala`, or `.p8bank` file.

During development this means an old DAW project can keep running old firmware code until
the console patch tool is pointed at the current firmware again. Once the patch has been
loaded from the console, changes to the watched `.gazl` file are reloaded automatically.

## Practical Development Loop

1. Put the `.impala` source in the Permut8 firmware code folder.
2. Run the compile loop, or compile manually with `PikaCmd impala.pika compile`.
3. Open Permut8 in a DAW.
4. Open the built-in terminal from the logotype.
5. Log on and run the patch from the console.
6. Edit the `.impala` source.
7. Let the compile loop regenerate `.gazl`.
8. Let the console patch tool reload the changed `.gazl` automatically.
9. Run the patch again only when switching firmware names or changing configuration text.
10. Save a DAW project only when the currently loaded code is the version you want preserved in that project.

## Current Documentation Gaps

The exact console command set is not fully documented in this SDK yet. Public Sonic Charge posts confirm `logon`, `run patch`, firmware names, and optional configuration text, and the example sources document how `config`, `DEBUG`, `trace()`, and `.p8bank` loading differ. If the console has additional commands, they should be documented here once verified from Permut8 itself or original source material.
