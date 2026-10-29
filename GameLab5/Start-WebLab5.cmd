@echo off
cd /d "%~dp0"
where py >nul 2>nul
if %errorlevel% equ 0 (
    py -3 "%~dp0serve.py"
) else (
    python "%~dp0serve.py"
)
pause
