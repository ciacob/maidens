@echo off
SET executable="%~dp0..\bin-release-src\MAIDENS\MAIDENS.exe"
SET certificate="%~dp0..\..\..\..\..\_BUILD_\CERTIFICATES\win\ciacob-test-2.pfx"
setlocal
SET password="%win-cert-pass%"
signtool.exe sign /f %certificate% /p %password% /v /tr http://timestamp.digicert.com?alg=sha256 /td SHA256 /fd SHA256 %executable%
endlocal