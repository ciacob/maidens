@echo off
REM Save current dir
set "currentdir=%cd%"

REM Go to the output directory and get the name of the file it contains
cd ..\..\..\dist-out
FOR /F "tokens=* USEBACKQ" %%F IN (`dir /b`) DO (
SET installerfile=%%F
)
ECHO installer file is: %installerfile%

REM Get back and run signtool on the installer file
cd %currentdir%
SET executable="%~dp0..\..\..\dist-out\%installerfile%"
SET certificate="%~dp0..\..\..\..\..\..\..\_BUILD_\p12\ciacob.pfx"

setlocal
SET password="%win-cert-pass%"
signtool.exe sign /f %certificate% /p %password% /v /tr http://timestamp.digicert.com?alg=sha256 /td SHA256 /fd SHA256 %executable%
endlocal