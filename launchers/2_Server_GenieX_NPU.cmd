@echo off
title Server GenieX NPU (Porta 18181) - Qwen3-8B e Qwen3.8-27B su Hexagon NPU
setlocal enabledelayedexpansion

set GENIEX_BIN=%LOCALAPPDATA%\GenieX CLI\geniex.exe

if not exist "%GENIEX_BIN%" (
    where geniex >nul 2>&1
    if %errorlevel% equ 0 (
        set GENIEX_BIN=geniex
    ) else (
        echo [ERRORE] GenieX CLI non trovato in "%GENIEX_BIN%" ne nel PATH.
        echo Installa GenieX da https://geniex.ai o esegui scripts\setup_toolchain.ps1
        pause
        exit /b 1
    )
)

echo =========================================================================
echo  Avvio Server GenieX NPU su http://127.0.0.1:18181/v1
echo  Acceleratore : Qualcomm Hexagon NPU (HTP0 fino a 80 TOPS) - Max Efficienza
echo  Modelli NPU  : 
echo    * 8B  : unsloth/Qwen3-8B-128K-GGUF:Q4_0 (~18 tok/s decode, ~837 tok/s prefill)
echo    * 27B : IvanKrastevAdventics/Qwen3.8-27B-AWQ-INT4-Q4_0-GGUF:Q4_0 (~5 tok/s)
echo  Hardware     : Qualcomm Snapdragon X2 Elite Extreme (48GB UMA, 228 GB/s)
echo =========================================================================
echo.

"%GENIEX_BIN%" serve -c npu --nctx 16384

pause