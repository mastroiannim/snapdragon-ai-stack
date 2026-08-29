@echo off
title Server GenieX NPU (Porta 18181) - Hexagon NPU 80 TOPS (Gemma 4 E2B, Phi-4 Mini, Qwen3-4B, Qwen 8B, Qwen 27B)
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
echo  Acceleratore : Qualcomm Hexagon NPU (HTP0 fino a 80 TOPS) - Max Efficienza (4W-8W)
echo  Modelli NPU  : 
echo    * 2.3B: google/gemma-4-E2B-it-qat-q4_0-gguf (~35.1 tok/s decode, ~1.808 tok/s prefill)
echo    * 3.8B: unsloth/Phi-4-mini-instruct-GGUF (~18.1 tok/s decode, ~1.276 tok/s prefill)
echo    * 4B  : unsloth/Qwen3-4B-Instruct-2507-GGUF (~20-28 tok/s decode, ~1.100+ tok/s prefill)
echo    * 8B  : unsloth/Qwen3-8B-128K-GGUF (~18-25 tok/s decode, ~837 tok/s prefill)
echo    * 27B : IvanKrastevAdventics/Qwen3.8-27B-AWQ-INT4-Q4_0-GGUF (~5-8 tok/s)
echo  Hardware     : Qualcomm Snapdragon X2 Elite Extreme (48GB UMA, 228 GB/s)
echo =========================================================================
echo.

"%GENIEX_BIN%" serve -c npu --nctx 8192

pause