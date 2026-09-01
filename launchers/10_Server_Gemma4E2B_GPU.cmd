@echo off
title Server Gemma 4 E2B-it (Porta 18189) - GPU Adreno Vulkan
setlocal enabledelayedexpansion

set REPO_ROOT=%~dp0..
set LLAMA_BIN=%REPO_ROOT%\bin\llama-cpp-vulkan-arm64\llama-server.exe
if not exist "%LLAMA_BIN%" set LLAMA_BIN=%USERPROFILE%\bin\llama-cpp-vulkan-arm64\llama-server.exe

set MODEL_PATH=%REPO_ROOT%\models\Gemma-4-E2B\gemma-4-E2B_q4_0-it.gguf
if not exist "%MODEL_PATH%" set MODEL_PATH=%REPO_ROOT%\models\Gemma-4-E2B\gemma-4-E2B-it-qat-UD-Q4_K_XL.gguf
if not exist "%MODEL_PATH%" set MODEL_PATH=%REPO_ROOT%\models\Gemma-4-E2B\gemma-4-e2b-it-qat-q4_0.gguf
if not exist "%MODEL_PATH%" set MODEL_PATH=%USERPROFILE%\models\Gemma-4-E2B\gemma-4-E2B_q4_0-it.gguf
if not exist "%MODEL_PATH%" set MODEL_PATH=%USERPROFILE%\models\Gemma-4-E2B\gemma-4-E2B-it-qat-UD-Q4_K_XL.gguf
if not exist "%MODEL_PATH%" set MODEL_PATH=%USERPROFILE%\.cache\geniex\models\google\gemma-4-E2B-it-qat-q4_0-gguf\gemma-4-E2B_q4_0-it.gguf
if not exist "%MODEL_PATH%" set MODEL_PATH=%USERPROFILE%\.cache\geniex\models\unsloth\gemma-4-E2B-it-qat-GGUF\gemma-4-E2B-it-qat-UD-Q4_K_XL.gguf

rem Disabilita int dot / coopmat per compatibilita shader Adreno Vulkan
set GGML_VK_DISABLE_INTEGER_DOT_PRODUCT=1
set GGML_VK_DISABLE_COOPMAT=1

if not exist "%LLAMA_BIN%" (
    echo [ERRORE] llama-server.exe non trovato in: "%LLAMA_BIN%"
    pause
    exit /b 1
)

if not exist "%MODEL_PATH%" (
    echo [ERRORE] Modello Gemma-4-E2B-it non trovato. Scaricalo tramite: scripts\download_models.ps1
    pause
    exit /b 1
)

echo =========================================================================
echo  Avvio Server Gemma-4-E2B-it su http://127.0.0.1:18189/v1
echo  ID Modello   : Gemma-4-E2B-Adreno-GPU
echo  Acceleratore : Qualcomm Adreno GPU (Vulkan Nativo 1.85 GHz) + CPU Oryon
echo  Velocita     : ~65-90 tok/s GPU / ~35.1 tok/s NPU (Prefill NPU ~1.808 tok/s)
echo  Origine      : Qualcomm AI Hub (https://aihub.qualcomm.com/models/gemma_4_e2b_it)
echo  Modalita     : Multimodale (Testo, Immagini), Reasoning Veloce e Coding
echo  Hardware     : Qualcomm Snapdragon X2 Elite Extreme (48GB UMA, 228 GB/s)
echo =========================================================================
echo.

"%LLAMA_BIN%" ^
  -m "%MODEL_PATH%" ^
  -ngl 99 ^
  --host 127.0.0.1 ^
  --port 18189 ^
  --alias "Gemma-4-E2B-Adreno-GPU" ^
  -c 65536 ^
  -np 1 ^
  -t 8 ^
  -lv 0

pause
