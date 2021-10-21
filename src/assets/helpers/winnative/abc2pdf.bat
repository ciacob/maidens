@ECHO OFF

IF [%1]==[] GOTO Continue
IF [%2]==[] GOTO Continue

call abc2ps.bat %1 %2
call ps2pdf.bat %1 %2

echo ABC TO PDF CONVERSION DONE FOR^: %1
GOTO End

:Continue
echo Usage: abc2pdf.bat ^<sessionName^> ^<homeDir^>

:End