@ECHO OFF

IF [%1]==[] GOTO Continue
IF [%2]==[] GOTO Continue

gswin32c.exe -dSAFER -dBATCH -dNOPAUSE -sDEVICE=pdfwrite -r600 -sOutputFile=%2\%1.pdf %2\%1.ps
echo PDF CONVERSION DONE FOR^: %1

GOTO End

:Continue
echo Usage: ps2pdf.bat ^<sessionName^> ^<homeDir^>

:End