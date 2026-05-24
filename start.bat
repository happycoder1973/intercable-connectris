@echo off
cd /d "%~dp0"
set EXE_NAME=IntercableConnectris.exe

if exist "%EXE_NAME%" (
    echo Starting %EXE_NAME%...
    start "" "%EXE_NAME%"
) else (
    echo Executable %EXE_NAME% not found in the current directory.
    echo Please make sure the project is exported as %EXE_NAME%.
    pause
)
