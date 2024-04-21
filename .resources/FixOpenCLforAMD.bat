@echo off
cls
echo OpenCL Driver (ICD) Fix for AMD GPU's
echo By Patrick Trumpis (https://github.com/ptrumpis/OpenCL-AMD-GPU)
echo Inspired by https://stackoverflow.com/a/28407851
echo:

>nul 2>&1 "%SYSTEMROOT%\System32\cacls.exe" "%SYSTEMROOT%\System32\config\system" && (
    goto run
) || (
    echo Execution stopped
    echo =================
    echo This script requires administrator rights.
    echo Please run it again as administrator.
    echo You can right-click the file and select 'Run as administrator'
    echo:
    pause
    exit /b 1
)

:run
SETLOCAL EnableDelayedExpansion

SET ROOTKEY64=HKEY_LOCAL_MACHINE\SOFTWARE\Khronos\OpenCL\Vendors
SET ROOTKEY32=HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Khronos\OpenCL\Vendors

echo Currently installed OpenCL Client Driver's - 64bit
echo ==================================================
reg query %ROOTKEY64%
echo:

echo Currently installed OpenCL Client Driver's - 32bit
echo ==================================================
reg query %ROOTKEY32%
echo:

echo:
echo This script will now attempt to find and install unregistered OpenCL AMD drivers from Windows (Fast Scan).
echo:

:askUserFastScan
set "INPUT="
set /P "INPUT=Do you want to continue with the Fast Scan? (Y/N): "
if /I "!INPUT!" == "Y" (
    echo Running AMD OpenCL Driver Auto Detection
    goto scanFilesFast
) else if /I "!INPUT!" == "N" (
    goto askUserFullScan
) else (
    echo Invalid input, please try again.
    goto askUserFastScan
)

:scanFilesFast
echo:
echo Scanning '%SYSTEMROOT%\system32' for 'amdocl*.dll' files, please wait...
cd /d %SYSTEMROOT%\system32
call :registerMissingClientDriver
echo Fast Scan complete.
echo:
goto askUserFullScan

:askUserFullScan
set "INPUT="
set /P "INPUT=Do you want to continue with the Full Scan? (Y/N): "
if /I "!INPUT!" == "Y" (
    echo Running Full AMD OpenCL Driver Detection
    goto scanFilesFull
) else if /I "!INPUT!" == "N" (
    goto complete
) else (
    echo Invalid input, please try again.
    goto askUserFullScan
)

:scanFilesFull
echo:
echo Now scanning your PATH for 'amdocl*.dll' files, please wait...
for %%A in ("%path:;=";"%") do (
    if exist "%%~A\amdocl*.dll" (
        cd /d "%%~A"
        call :registerMissingClientDriver
    )
)
echo Full Scan complete.
echo:
goto complete

:complete
echo Done.
pause
exit /b 0

:registerMissingClientDriver
for /r %%f in (amdocl*.dll) do (
    set FILE="%%~dpnxf"
    for %%A in (amdocl.dll amdocl12cl.dll amdocl12cl64.dll amdocl32.dll amdocl64.dll) do (
        if "%%~nxf"=="%%A" (
            echo Found: !FILE!
            echo !FILE! | findstr /C:"_amd64_" >nul
            if !ERRORLEVEL! == 0 (
                set "ROOTKEY=!ROOTKEY64!"
            ) else (
                set "ROOTKEY=!ROOTKEY32!"
            )

            reg query !ROOTKEY! /v !FILE! >nul 2>&1
            if !ERRORLEVEL! neq 0 (
                reg add !ROOTKEY! /v !FILE! /t REG_SZ /d 0 /f >nul 2>&1
                if !ERRORLEVEL! == 0 (
                    echo Installed: !FILE!
                )
            )
        )
    )
)
goto :eof
