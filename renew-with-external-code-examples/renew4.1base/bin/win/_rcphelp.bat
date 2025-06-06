@ECHO OFF
REM Renew Classpath Helper (rcphelp.bat)
IF NOT EXIST %1 GOTO Warning
SET CLASSPATH=%CLASSPATH%;%1
GOTO End

:Warning
ECHO !!! Non-existing library: %1
ECHO !!! Probably you should re-run installrenew.bat.

:End
