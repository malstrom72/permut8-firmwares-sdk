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
SET src_nuxjs=GAZL\externals\NuXJS
SET src_validator=GAZL\tools\gazl-validate.js
SET dst=examples\Firmwares
SET bin=tools\bin

FOR %%f IN (^
	"%src_impala%\impala.nuxjs.js" ^
	"%src_impala%\impalaCompiler.js" ^
	"%src_validator%" ^
	"%src_nuxjs%\tools\NuXJSREPL.cpp" ^
	"%src_nuxjs%\src\NuXJS.cpp" ^
	"%src_nuxjs%\src\stdlibJS.cpp") DO (
	IF NOT EXIST "%%~f" (
		ECHO Missing expected source file: %%~f >&2
		EXIT /B 1
	)
)

IF NOT EXIST "%dst%" MKDIR "%dst%"
IF NOT EXIST "%bin%" MKDIR "%bin%"

REM Build the NuXJS command-line runtime that executes the Impala compiler.
CALL GAZL\tools\BuildCpp.cmd %target% %model% "%bin%\NuXJS.exe" ^
	"%src_nuxjs%\tools\NuXJSREPL.cpp" ^
	"%src_nuxjs%\src\NuXJS.cpp" ^
	"%src_nuxjs%\src\stdlibJS.cpp"
IF ERRORLEVEL 1 EXIT /B 1

COPY /Y "%bin%\NuXJS.exe" "%dst%\NuXJS.exe" >NUL

REM Copy NuXJS (prebuilt for macOS/Linux) if present, so the bundle stays cross-platform.
IF EXIST "%bin%\NuXJS" COPY /Y "%bin%\NuXJS" "%dst%\NuXJS" >NUL

REM Stage the JSPEG-generated Impala compiler. It is pre-generated upstream, so no
REM rebuild step is needed here; impala.nuxjs.js auto-loads impalaCompiler.js from
REM its own directory, so both files must sit side by side wherever NuXJS runs.
COPY /Y "%src_impala%\impala.nuxjs.js"   "%dst%\impala.nuxjs.js"   >NUL
COPY /Y "%src_impala%\impalaCompiler.js" "%dst%\impalaCompiler.js" >NUL
COPY /Y "%src_impala%\impala.nuxjs.js"   "%bin%\impala.nuxjs.js"   >NUL
COPY /Y "%src_impala%\impalaCompiler.js" "%bin%\impalaCompiler.js" >NUL

REM Stage the GAZL signature validator next to the other SDK tools. Run it from the
REM SDK root so it auto-loads the Permut8 native manifest at docs\nativeCallbackSignatures.gazl:
REM   tools\bin\NuXJS tools\gazl-validate.js <compiled>.gazl
COPY /Y "%src_validator%" "tools\gazl-validate.js" >NUL

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
