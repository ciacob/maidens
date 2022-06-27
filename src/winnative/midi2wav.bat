@ECHO OFF

IF [%1]==[] GOTO Continue
IF [%2]==[] GOTO Continue

pushd..
set parent=%cd%
popd

REM abc2midi adds a trailing `1` char to the file name upon conversion
fluidsynth.exe -i -n -g 0.3 -F %2\%1.wav "%parent%\assets\helpers\soundfonts\MAIDENS.SF2" %2\%1.mid

echo RECORDING TO WAV DONE FOR^: %1

GOTO End

:Continue
echo Usage: midi2wav.bat ^<sessionName^> ^<homeDir^>

:End