#!/usr/bin/env bash
set -euo pipefail

# Mirror the IVG-sourced documentation from the vendored snapshot in IVG/docs/
# into the top-level docs/ folder. IVG/docs/ is the source of truth (it is a
# vendored copy of the upstream IVG repo); docs/ is the copy referenced for
# firmware authoring and by the agent packages.
#
# Usage:
#   tools/sync-ivg-docs.sh          copy IVG/docs/ -> docs/ (default)
#   tools/sync-ivg-docs.sh --check  verify the two are in sync; non-zero exit on drift

cd "$(dirname "$0")/.."

src="IVG/docs"
dst="docs"

# Files mirrored from the vendored snapshot. IVG/docs/ also carries
# "ivgfont Documentation.md" and "NuXPixels Documentation.md", which are
# intentionally not shipped in docs/, so they are excluded here.
files=(
	"IVG Documentation.md"
	"IVG Documentation.html"
	"ImpD Documentation.md"
	"ImpD Documentation.html"
)

check=0
if [ "${1:-}" = "--check" ]; then
	check=1
elif [ -n "${1:-}" ]; then
	echo "usage: $0 [--check]" >&2
	exit 2
fi

status=0

compare_or_copy() {
	local from="$1" to="$2" label="$3"
	if [ ! -e "$from" ]; then
		echo "missing source: $from" >&2
		status=1
		return
	fi
	if [ "$check" -eq 1 ]; then
		if ! cmp -s "$from" "$to"; then
			echo "out of sync: $label" >&2
			status=1
		fi
	else
		if cmp -s "$from" "$to" 2>/dev/null; then
			echo "unchanged $label"
		else
			cp "$from" "$to"
			echo "synced    $label"
		fi
	fi
}

for f in "${files[@]}"; do
	compare_or_copy "$src/$f" "$dst/$f" "$f"
done

# Mirror the doc images referenced by the markdown/html above.
while IFS= read -r -d '' img; do
	rel="${img#"$src"/images/}"
	compare_or_copy "$img" "$dst/images/$rel" "images/$rel"
done < <(find "$src/images" -type f -print0)

if [ "$check" -eq 1 ]; then
	if [ "$status" -ne 0 ]; then
		echo "docs/ is out of sync with $src — run tools/sync-ivg-docs.sh" >&2
	else
		echo "docs/ is in sync with $src"
	fi
fi

exit "$status"
