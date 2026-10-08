@ECHO OFF
SETLOCAL ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION
CD /D "%~dp0.."
REM Run one compiled Permut8 firmware and print its deterministic output checksum.
REM See runPermut8Firmware.sh for what the harness does and what the checksum does and does not prove.
REM Usage: tools\runPermut8Firmware.cmd <firmware.gazl> [extra GAZLCmd args]

IF "%~1"=="" (
	ECHO usage: tools\runPermut8Firmware.cmd ^<firmware.gazl^> [extra GAZLCmd args] 1>&2
	EXIT /B 1
)
IF NOT EXIST "%~1" (
	ECHO runPermut8Firmware: no such file: %~1 1>&2
	EXIT /B 1
)

SET "FW=%~1"
SET "NAME=%~n1"
SHIFT

SET "WORK=%TEMP%\permut8-host-%RANDOM%%RANDOM%"
MKDIR "%WORK%" 2>NUL
SET "HOST=%WORK%\%NAME%.gazl"

tools\bin\NuXJS.exe tools\permut8Host.nuxjs.js "%FW%" "%HOST%" 1>&2
IF ERRORLEVEL 1 (
	RMDIR /S /Q "%WORK%" 2>NUL
	EXIT /B 1
)

REM Auto-flags: a firmware that ships its own libm, or a global colliding with a built-in native name.
SET EXTRA=
FINDSTR /R /C:"^[ 	]*sqrt:" /C:"^[ 	]*log:" /C:"^[ 	]*atan2:" "%FW%" >NUL 2>&1 && SET EXTRA=--no-libm
FOR %%N IN (input print printInt printFloat printLF exit) DO (
	FINDSTR /R /C:"^%%N:" "%FW%" >NUL 2>&1 && SET EXTRA=!EXTRA! --no-native=%%N
)

REM The harness prints the checksum on a line of its own (permut8Host emits a trailing printLF), so the
REM whole-line match below is all the parsing needed.
IF NOT DEFINED GAZLCMD SET GAZLCMD=tools\bin\GAZLCmd.exe
REM No `$` anchor: the emitted line ends CR-LF and FINDSTR would not match past the CR. Nothing else in
REM the output begins with an optional minus followed by a digit ("Code size:", "Status:", and the rule
REM of dashes all fail that), so the leading anchor alone is unambiguous.
REM --forward must be QUOTED: inside FOR /F, cmd re-parses the command line and treats the commas in
REM the nat:func list as argument separators, so GAZLCmd would see a bare "--forward" and reject it.
FOR /F "delims=" %%L IN ('%GAZLCMD% "%HOST%" hostMain "--forward=yield:yield_,read:read_,write:write_,trace:trace_" !EXTRA! %1 %2 %3 2^>NUL ^| FINDSTR /R /C:"^-*[0-9][0-9]*"') DO (
	IF NOT DEFINED SUM SET "SUM=%%L"
)

RMDIR /S /Q "%WORK%" 2>NUL
IF NOT DEFINED SUM EXIT /B 1
ECHO !SUM!
EXIT /B 0
