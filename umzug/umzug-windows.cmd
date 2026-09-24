@echo off
rem Startet das Umzugsskript unter Windows, ohne die PowerShell-Richtlinie zu aendern.
rem Aufruf in der Eingabeaufforderung: umzug-windows.cmd pruefen   (siehe ANLEITUNG.md)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0umzug.ps1" %*
set RC=%ERRORLEVEL%
pause
exit /b %RC%
