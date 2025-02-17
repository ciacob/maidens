@echo off
set "currDir=%cd%"

echo.
REM Empty the "distOutFolder" of any previously compiled installers.
echo Emptying the installer binaries folder...
set distOutFolder="%~dp0..\..\..\dist-out"
cd /d %distOutFolder%
for /F "delims=" %%i in ('dir /b') do (rmdir "%%i" /s/q || del "%%i" /s/q) >nul 2>&1
cd "%currDir%"

echo.
REM Empty the "distInterim" of any previously patched binaries.
echo Emptying the installer sources folder...
set distInterim="%~dp0..\..\..\dist-interim"
cd /d %distInterim%
for /F "delims=" %%i in ('dir /b') do (rmdir "%%i" /s/q || del "%%i" /s/q) >nul 2>&1
cd "%currDir%"

REM Copy original binaries, aka the files originally "packed" by AIR
echo.
echo Copying bundled application...
set distSrcFolder="%~dp0..\..\..\dist-src"
robocopy "%distSrcFolder%" "%distInterim%" /E

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