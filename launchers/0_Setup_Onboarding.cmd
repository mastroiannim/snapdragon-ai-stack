@echo off
title Onboarding e Setup Risorse Snapdragon AI Stack
setlocal enabledelayedexpansion

echo =========================================================================
echo  Snapdragon AI Stack: Wizard di Onboarding e Diagnostica Risorse
echo  Scopo        : Verifica e configurazione ambiente, WSL2, driver e modelli
echo  Hardware     : Qualcomm Snapdragon X (ARM64 Windows)
echo =========================================================================
echo.

set SCRIPT_PATH=%~dp0..\scripts\onboarding.ps1

powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_PATH%"

echo.
pause
