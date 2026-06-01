#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

src_impala="GAZL/impala"
src_pikacmd="GAZL/externals/PikaCmd"
dst="examples/Firmwares"

for path in "$src_impala/impala.pika" "$src_impala/impalaCompiler.pika" "$src_impala/systools.pika"; do
	if [ ! -f "$path" ]; then
		echo "Missing expected source file: $path" >&2
		exit 1
	fi
done

mkdir -p "$dst"

cp "$src_impala/impala.pika" "$dst/impala.pika"
cp "$src_impala/impalaCompiler.pika" "$dst/impalaCompiler.pika"
cp "$src_impala/systools.pika" "$dst/systools.pika"

if [ -f "$src_pikacmd/PikaCmd" ]; then
	cp "$src_pikacmd/PikaCmd" "$dst/PikaCmd"
	chmod +x "$dst/PikaCmd"
else
	echo "Warning: $src_pikacmd/PikaCmd not found; leaving $dst/PikaCmd unchanged" >&2
fi

if [ -f "$src_pikacmd/PikaCmd.exe" ]; then
	cp "$src_pikacmd/PikaCmd.exe" "$dst/PikaCmd.exe"
fi

echo "Updated firmware toolchain files in $dst from GAZL."
