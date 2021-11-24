@ECHO OFF

IF [%1]==[] GOTO Continue

REM Forecefully ends the "fluidsynth.exe" process.
taskkill /F /IM fluidsynth.exe

echo MIDI PLAYBACK STOPPED FOR^: %1

GOTO End

:Continue
echo Usage: playMidi.bat ^<sessionName^>

:End