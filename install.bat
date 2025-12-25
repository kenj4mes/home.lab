@echo off
:: ============================================================================
:: HomeLab One-Click Installer
:: Double-click this file to start the Install Wizard
:: ============================================================================

title HomeLab Install Wizard

:: Check for admin privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo  [!] Administrator privileges required
    echo  [i] Right-click install.bat and select "Run as administrator"
    echo.
    pause
    exit /b 1
)

:: Run the PowerShell wizard
powershell -ExecutionPolicy Bypass -NoProfile -File "%~dp0install\install-wizard.ps1"

pause
