@ECHO OFF

IF [%1]==[] GOTO Continue
IF [%2]==[] GOTO Continue

abc2midi.exe "%2\%1.abc" 1 -o "%2\%1.mid"
echo MIDI CONVERSION DONE FOR^: %1

GOTO End

:Continue
echo Usage: abc2midi.bat ^<sessionName^> ^<homeDir^>

:End