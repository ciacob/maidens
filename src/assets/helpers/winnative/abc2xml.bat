@ECHO OFF

IF [%1]==[] GOTO Continue
IF [%2]==[] GOTO Continue

abc2xml.exe %2\%1.abc -o %2

echo ABC TO XML CONVERSION DONE FOR^: %1

GOTO End

:Continue
echo Usage: abc2xml.bat ^<sessionName^> ^<homeDir^>

:End