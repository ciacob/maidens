@ECHO OFF

IF [%1]==[] GOTO Continue
IF [%2]==[] GOTO Continue

pushd..
set parent=%cd%
popd

fluidsynth.exe -i -n -g 0.3 "%parent%\soundfonts\MAIDENS.SF2" "%2\%1.mid"

echo PLAYBACK DONE FOR^: %1

GOTO End

:Continue
echo Usage: playMidi.bat ^<sessionName^> ^<homeDir^>

:End