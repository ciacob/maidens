@echo off
set "currDir=%cd%"

echo.
REM Empty the raw binaries folder
echo Emptying the installer binaries folder...
set installerBinariesFolder="%~dp0..\bin-release-src"
cd /d %installerBinariesFolder%
for /F "delims=" %%i in ('dir /b') do (rmdir "%%i" /s/q || del "%%i" /s/q) >nul 2>&1
cd "%currDir%"

REM Copy binaries over from project
echo.
echo Copying bundled application...
set projectBinariesFolder="%~dp0..\..\..\bin\maidens"
robocopy "%projectBinariesFolder%" "%installerBinariesFolder%\MAIDENS" /E

REM Change main executable icon
echo.
echo Patching application main executable...
CALL add-exe-icon.bat

REM Since we tampered with the main executable, we need to resign it
echo.
echo (Re)signing application main executable...
CALL sign-app-exe.bat

REM Compile the installer package
echo.
echo Compiling windows installer...
CALL compile-installer.bat

REM Sign the installer package itself
echo.
echo Signing the installer package...
CALL sign-installer.bat