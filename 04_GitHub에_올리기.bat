@echo off
rem Uploads the textbook to GitHub.
rem All Korean screens and logic live in scripts\textbook.ps1 (kept ASCII here so cmd reads it on any code page).
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\textbook.ps1" github
if errorlevel 1 pause
