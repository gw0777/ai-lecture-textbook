@echo off
rem Builds an offline copy of the textbook into a folder on the Desktop.
rem All Korean screens and logic live in scripts\textbook.ps1 (kept ASCII here so cmd reads it on any code page).
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\textbook.ps1" offline
if errorlevel 1 pause
