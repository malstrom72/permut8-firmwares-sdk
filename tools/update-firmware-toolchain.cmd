@ECHO OFF
SETLOCAL ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

CD /D "%~dp0.."

SET target=%~1
SET model=%~2
SET simd=%~3
IF "%target%"=="" SET target=release
IF "%model%"=="" SET model=native
IF "%simd%"=="" SET simd=nosimd

IF "%simd%"=="simd" (
	SET simd_flag=1
) ELSE IF "%simd%"=="nosimd" (
	SET simd_flag=0
) ELSE (
	ECHO Usage: tools\update-firmware-toolchain.cmd [debug^|beta^|release] [x86^|x64^|arm64^|native] [nosimd^|simd] >&2
	EXIT /B 1
)

SET src_impala=GAZL\impala
SET dst=examples\Firmwares
SET bin=tools\bin

FOR %%f IN ("%src_impala%\impala.pika" "%src_impala%\impalaCompiler.pika" "%src_impala%\systools.pika") DO (
	IF NOT EXIST "%%~f" (
		ECHO Missing expected source file: %%~f >&2
		EXIT /B 1
	)
)

IF NOT EXIST "%dst%" MKDIR "%dst%"
IF NOT EXIST "%bin%" MKDIR "%bin%"

REM Copy PikaCmd.exe (prebuilt for Windows)
IF EXIST "%bin%\PikaCmd.exe" (
	COPY /Y "%bin%\PikaCmd.exe" "%dst%\PikaCmd.exe" >NUL
) ELSE (
	ECHO Missing %bin%\PikaCmd.exe >&2
	EXIT /B 1
)

REM Rebuild Impala compiler pika files
PUSHD "%src_impala%"
CALL "..\..\%bin%\PikaCmd.exe" impala.pika rebuild
IF ERRORLEVEL 1 ( POPD & EXIT /B 1 )
POPD

COPY /Y "%src_impala%\impala.pika"         "%dst%\impala.pika"         >NUL
COPY /Y "%src_impala%\impalaCompiler.pika" "%dst%\impalaCompiler.pika" >NUL
COPY /Y "%src_impala%\systools.pika"       "%dst%\systools.pika"       >NUL
COPY /Y "%src_impala%\impala.pika"         "%bin%\impala.pika"         >NUL
COPY /Y "%src_impala%\impalaCompiler.pika" "%bin%\impalaCompiler.pika" >NUL
COPY /Y "%src_impala%\systools.pika"       "%bin%\systools.pika"       >NUL

REM Build IVG2PNG.exe
SET CPP_OPTIONS=/DNUXPIXELS_SIMD=%simd_flag%
CALL GAZL\tools\BuildCpp.cmd %target% %model% ^
	"%bin%\IVG2PNG.exe" ^
	/I IVG /I IVG\externals /I IVG\externals\libpng /I IVG\externals\zlib ^
	IVG\tools\IVG2PNG.cpp ^
	IVG\src\IVG.cpp ^
	IVG\src\IMPD.cpp ^
	IVG\externals\NuX\NuXPixels.cpp ^
	IVG\externals\libpng\png.c ^
	IVG\externals\libpng\pngerror.c ^
	IVG\externals\libpng\pngget.c ^
	IVG\externals\libpng\pngmem.c ^
	IVG\externals\libpng\pngpread.c ^
	IVG\externals\libpng\pngread.c ^
	IVG\externals\libpng\pngrio.c ^
	IVG\externals\libpng\pngrtran.c ^
	IVG\externals\libpng\pngrutil.c ^
	IVG\externals\libpng\pngset.c ^
	IVG\externals\libpng\pngtrans.c ^
	IVG\externals\libpng\pngwio.c ^
	IVG\externals\libpng\pngwrite.c ^
	IVG\externals\libpng\pngwtran.c ^
	IVG\externals\libpng\pngwutil.c ^
	IVG\externals\zlib\adler32.c ^
	IVG\externals\zlib\compress.c ^
	IVG\externals\zlib\crc32.c ^
	IVG\externals\zlib\deflate.c ^
	IVG\externals\zlib\infback.c ^
	IVG\externals\zlib\inffast.c ^
	IVG\externals\zlib\inflate.c ^
	IVG\externals\zlib\inftrees.c ^
	IVG\externals\zlib\trees.c ^
	IVG\externals\zlib\uncompr.c ^
	IVG\externals\zlib\zutil.c
IF ERRORLEVEL 1 EXIT /B 1

ECHO Updated SDK tool binaries in %bin% and firmware runtime files in %dst%.
