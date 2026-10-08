#!/usr/bin/env bash
#
# Regression check: run every example firmware through the Permut8 host harness and compare its output
# checksum against tools/permut8FirmwareChecksums.txt. Exits non-zero on any mismatch.
#
# This is the SDK's answer to "did that change anything?". Run it after editing a firmware, bumping the
# toolchain, re-mirroring GAZL, or porting sources to newer Impala idioms. A firmware whose checksum is
# unchanged produced byte-identical audio over a fixed 100000-frame run.
#
# It proves equality, not correctness - it cannot tell you a firmware sounds good, only that it sounds
# the same as before. Loading the bank in Permut8 remains the final check.
#
# Usage:
#   bash tools/checkPermut8Firmwares.sh              compare against the committed checksums
#   bash tools/checkPermut8Firmwares.sh --update     rewrite them (only when a change is intended)
set -u -o pipefail
cd "$(dirname "$0")/.."

MANIFEST=tools/permut8FirmwareChecksums.txt
update=0
[ "${1:-}" = "--update" ] && update=1

if [ "$update" -eq 1 ]; then
	tmp="$MANIFEST.new"
	grep '^#' "$MANIFEST" > "$tmp"
	for f in examples/Firmwares/*_code.gazl; do
		n=$(basename "$f" .gazl)
		printf '%-22s %s\n' "$n" "$(bash tools/runPermut8Firmware.sh "$f" 2>/dev/null)" >> "$tmp"
	done
	mv "$tmp" "$MANIFEST"
	echo "Updated $MANIFEST."
	exit 0
fi

fails=0
count=0
for f in examples/Firmwares/*_code.gazl; do
	name=$(basename "$f" .gazl)
	want=$(awk -v n="$name" '$1 == n { print $2 }' "$MANIFEST")
	got=$(bash tools/runPermut8Firmware.sh "$f" 2>/dev/null)
	count=$((count + 1))
	if [ -z "$want" ]; then
		printf '%-22s %-14s NO BASELINE (add it with --update)\n' "$name" "$got"
		fails=$((fails + 1))
	elif [ "$got" = "$want" ]; then
		printf '%-22s %-14s ok\n' "$name" "$got"
	else
		printf '%-22s %-14s CHANGED (expected %s)\n' "$name" "$got" "$want"
		fails=$((fails + 1))
	fi
done

# A firmware listed in the manifest but no longer present is a stale entry, not a pass.
while read -r name _; do
	case "$name" in '#'*|'') continue;; esac
	[ -f "examples/Firmwares/$name.gazl" ] || { printf '%-22s %-14s MISSING (in manifest, not on disk)\n' "$name" "-"; fails=$((fails + 1)); }
done < "$MANIFEST"

echo
if [ "$fails" -eq 0 ]; then
	echo "All $count firmware checksums match."
else
	echo "$fails FAILURE(S)."
	exit 1
fi
