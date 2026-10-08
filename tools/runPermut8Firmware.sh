#!/usr/bin/env bash
#
# Run one compiled Permut8 firmware (an UNMODIFIED *.gazl) and print its deterministic output checksum.
#
# tools/permut8Host.nuxjs.js wraps the firmware in a pure-GAZL host - delay line, a fixed-seed
# pseudo-audio generator, and yield_/read_/write_/trace_ - then GAZLCmd executes it with --forward
# mapping the firmware's ^yield/^read/^write/^trace native calls onto those GAZL implementations. The
# firmware itself is copied in verbatim; nothing is patched.
#
# The checksum folds every output sample over a fixed 100000-frame run, so it is an equality oracle:
# two firmwares with the same checksum produced the same audio. Use it to confirm that a refactor,
# a toolchain bump, or a port to newer Impala idioms left behavior untouched.
#
# It is NOT a correctness check. A firmware can be badly wrong and still be self-consistent - only
# loading the bank in Permut8 tells you it sounds right.
#
# Usage: bash tools/runPermut8Firmware.sh <firmware.gazl> [extra GAZLCmd args]
set -e -o pipefail -u
cd "$(dirname "$0")/.."

if [ $# -lt 1 ]; then
	echo "usage: bash tools/runPermut8Firmware.sh <firmware.gazl> [extra GAZLCmd args]" >&2
	exit 1
fi

fw="$1"; shift || true
[ -f "$fw" ] || { echo "runPermut8Firmware: no such file: $fw" >&2; exit 1; }
name=$(basename "$fw" .gazl)

NUXJS=tools/bin/NuXJS
[ -x "$NUXJS" ] || NUXJS=tools/bin/NuXJS.exe
CMD=${GAZLCMD:-tools/bin/GAZLCmd}
[ -x "$CMD" ] || CMD=tools/bin/GAZLCmd.exe

work="${TMPDIR:-/tmp}/permut8-host-$$"					# keep generated harnesses out of the repo
mkdir -p "$work"
trap 'rm -rf "$work"' EXIT
host="$work/$name.gazl"

"$NUXJS" tools/permut8Host.nuxjs.js "$fw" "$host" 1>&2

# Auto-flags: a firmware that ships its own libm, or a global colliding with a built-in native name.
extra=""
grep -qE '^\s*(sqrt|log|atan2):\s+FUNC' "$fw" && extra="--no-libm"
for n in input print printInt printFloat printLF exit; do
	grep -qE "^$n:" "$fw" && extra="$extra --no-native=$n"
done

"$CMD" "$host" hostMain --forward=yield:yield_,read:read_,write:write_,trace:trace_ $extra "$@" \
	| grep -oE '^-?[0-9]+' | head -1
