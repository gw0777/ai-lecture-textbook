@echo off
rem Opens the textbook start menu.
rem All Korean screens and logic live in scripts\textbook.ps1 (kept ASCII here so cmd reads it on any code page).
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\textbook.ps1" menu
if errorlevel 1 pause
