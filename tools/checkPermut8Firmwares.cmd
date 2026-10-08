@ECHO OFF
SETLOCAL ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION
CD /D "%~dp0.."
REM Regression check: run every example firmware through the Permut8 host harness and compare its
REM output checksum against tools\permut8FirmwareChecksums.txt. Exits non-zero on any mismatch.
REM See checkPermut8Firmwares.sh for what the checksum does and does not prove.
REM Usage: tools\checkPermut8Firmwares.cmd

SET "MANIFEST=tools\permut8FirmwareChecksums.txt"
SET /A FAILS=0
SET /A COUNT=0

FOR %%F IN (examples\Firmwares\*_code.gazl) DO (
	SET "NAME=%%~nF"
	SET "WANT="
	FOR /F "tokens=1,2" %%A IN ('FINDSTR /B /C:"!NAME! " "%MANIFEST%"') DO SET "WANT=%%B"
	SET "GOT="
	FOR /F "delims=" %%L IN ('CALL tools\runPermut8Firmware.cmd "%%F" 2^>NUL') DO IF NOT DEFINED GOT SET "GOT=%%L"
	SET /A COUNT+=1
	IF NOT DEFINED WANT (
		ECHO !NAME!  !GOT!  NO BASELINE ^(add it with checkPermut8Firmwares.sh --update^)
		SET /A FAILS+=1
	) ELSE IF "!GOT!"=="!WANT!" (
		ECHO !NAME!  !GOT!  ok
	) ELSE (
		ECHO !NAME!  !GOT!  CHANGED ^(expected !WANT!^)
		SET /A FAILS+=1
	)
)

ECHO.
IF %FAILS%==0 (
	ECHO All %COUNT% firmware checksums match.
	EXIT /B 0
)
ECHO %FAILS% FAILURE^(S^).
EXIT /B 1
