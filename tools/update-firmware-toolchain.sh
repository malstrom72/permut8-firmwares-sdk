#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

target="${1:-release}"
model="${2:-native}"
simd="${3:-nosimd}"

case "$simd" in
	simd) simd_flag=1 ;;
	nosimd) simd_flag=0 ;;
	*)
		echo "Usage: tools/update-firmware-toolchain.sh [debug|beta|release] [x86|x64|arm64|native|fat] [nosimd|simd]" >&2
		exit 1
		;;
esac

src_impala="GAZL/impala"
src_nuxjs="GAZL/externals/NuXJS"
src_validator="GAZL/tools/gazl-validate.js"
dst="examples/Firmwares"
bin="tools/bin"
runtime_nuxjs="$bin/NuXJS"

for path in \
	"$src_impala/impala.nuxjs.js" \
	"$src_impala/impalaCompiler.js" \
	"$src_validator" \
	"$src_nuxjs/tools/NuXJSREPL.cpp" \
	"$src_nuxjs/src/NuXJS.cpp" \
	"$src_nuxjs/src/stdlibJS.cpp"; do
	if [ ! -f "$path" ]; then
		echo "Missing expected source file: $path" >&2
		exit 1
	fi
done

mkdir -p "$dst" "$bin"

# Build the NuXJS command-line runtime that executes the Impala compiler.
GAZL/tools/BuildCpp.sh "$target" "$model" "$runtime_nuxjs" \
	"$src_nuxjs/tools/NuXJSREPL.cpp" \
	"$src_nuxjs/src/NuXJS.cpp" \
	"$src_nuxjs/src/stdlibJS.cpp"
chmod +x "$runtime_nuxjs"

cp "$runtime_nuxjs" "$dst/NuXJS"
chmod +x "$dst/NuXJS"

if [ -f "$bin/NuXJS.exe" ]; then
	cp "$bin/NuXJS.exe" "$dst/NuXJS.exe"
fi

# Stage the JSPEG-generated Impala compiler. It is pre-generated upstream, so no
# rebuild step is needed here; impala.nuxjs.js auto-loads impalaCompiler.js from
# its own directory, so both files must sit side by side wherever NuXJS runs.
cp "$src_impala/impala.nuxjs.js" "$dst/impala.nuxjs.js"
cp "$src_impala/impalaCompiler.js" "$dst/impalaCompiler.js"
cp "$src_impala/impala.nuxjs.js" "$bin/impala.nuxjs.js"
cp "$src_impala/impalaCompiler.js" "$bin/impalaCompiler.js"

# Stage the GAZL signature validator next to the other SDK tools. Run it from the
# SDK root so it auto-loads the Permut8 native manifest at docs/nativeCallbackSignatures.gazl
# (the validator looks for ../docs/ relative to its own location):
#   tools/bin/NuXJS tools/gazl-validate.js <compiled>.gazl
cp "$src_validator" "tools/gazl-validate.js"

c_sources=(
	IVG/externals/libpng/png.c
	IVG/externals/libpng/pngerror.c
	IVG/externals/libpng/pngget.c
	IVG/externals/libpng/pngmem.c
	IVG/externals/libpng/pngpread.c
	IVG/externals/libpng/pngread.c
	IVG/externals/libpng/pngrio.c
	IVG/externals/libpng/pngrtran.c
	IVG/externals/libpng/pngrutil.c
	IVG/externals/libpng/pngset.c
	IVG/externals/libpng/pngtrans.c
	IVG/externals/libpng/pngwio.c
	IVG/externals/libpng/pngwrite.c
	IVG/externals/libpng/pngwtran.c
	IVG/externals/libpng/pngwutil.c
	IVG/externals/zlib/adler32.c
	IVG/externals/zlib/compress.c
	IVG/externals/zlib/crc32.c
	IVG/externals/zlib/deflate.c
	IVG/externals/zlib/infback.c
	IVG/externals/zlib/inffast.c
	IVG/externals/zlib/inflate.c
	IVG/externals/zlib/inftrees.c
	IVG/externals/zlib/trees.c
	IVG/externals/zlib/uncompr.c
	IVG/externals/zlib/zutil.c
)

IVG/tools/BuildCpp.sh "$target" "$model" "$bin/IVG2PNG" \
	-ffp-contract=off -UTARGET_OS_MAC IVG/tools/IVG2PNG.cpp -DNUXPIXELS_SIMD="$simd_flag" \
	-I IVG -I IVG/externals -I IVG/externals/libpng -I IVG/externals/zlib \
	IVG/src/IVG.cpp IVG/src/IMPD.cpp IVG/externals/NuX/NuXPixels.cpp \
	"${c_sources[@]}"

echo "Updated SDK tool binaries in $bin and firmware runtime files in $dst."
