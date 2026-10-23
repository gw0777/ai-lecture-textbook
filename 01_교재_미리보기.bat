@echo off
rem Previews the textbook site on this computer.
rem All Korean screens and logic live in scripts\textbook.ps1 (kept ASCII here so cmd reads it on any code page).
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\textbook.ps1" preview
if errorlevel 1 pause
