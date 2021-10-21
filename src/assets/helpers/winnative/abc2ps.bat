@ECHO OFF

IF [%1]==[] GOTO Continue
IF [%2]==[] GOTO Continue

abcm2ps.exe -N3 -c %2\%1.abc -O %2\%1.ps

echo ABC TO SVG CONVERSION DONE FOR^: %1

GOTO End

:Continue
echo Usage: abc2svg.bat ^<sessionName^> ^<homeDir^>

:End