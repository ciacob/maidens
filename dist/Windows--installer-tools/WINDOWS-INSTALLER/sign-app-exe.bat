@echo off
SET executable="%~dp0..\..\..\dist-interim\MAIDENS.exe"
SET certificate="%~dp0..\..\..\..\..\..\..\_BUILD_\p12\ciacob.pfx"
setlocal
SET password="%win-cert-pass%"
signtool.exe sign /f %certificate% /p %password% /v /tr http://timestamp.digicert.com?alg=sha256 /td SHA256 /fd SHA256 %executable%
endlocal