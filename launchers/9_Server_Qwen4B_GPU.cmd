@echo off
title Server Qwen3-4B-Instruct (Porta 18188) - GPU Adreno Vulkan
setlocal enabledelayedexpansion

set REPO_ROOT=%~dp0..
set LLAMA_BIN=%REPO_ROOT%\bin\llama-cpp-vulkan-arm64\llama-server.exe
if not exist "%LLAMA_BIN%" set LLAMA_BIN=%USERPROFILE%\bin\llama-cpp-vulkan-arm64\llama-server.exe

set MODEL_PATH=%REPO_ROOT%\models\Qwen3-4B\Qwen3-4B-Instruct-2507-Q4_K_M.gguf
if not exist "%MODEL_PATH%" set MODEL_PATH=%REPO_ROOT%\models\Qwen3-4B\Qwen3-4B-Q4_K_M.gguf
if not exist "%MODEL_PATH%" set MODEL_PATH=%REPO_ROOT%\models\Qwen3-4B\Qwen3-4B-Q4_0.gguf
if not exist "%MODEL_PATH%" set MODEL_PATH=%USERPROFILE%\models\Qwen3-4B\Qwen3-4B-Instruct-2507-Q4_K_M.gguf
if not exist "%MODEL_PATH%" set MODEL_PATH=%USERPROFILE%\models\Qwen3-4B\Qwen3-4B-Q4_K_M.gguf
if not exist "%MODEL_PATH%" set MODEL_PATH=%USERPROFILE%\.cache\geniex\models\unsloth\Qwen3-4B-Instruct-2507-GGUF\Qwen3-4B-Instruct-2507-Q4_K_M.gguf
if not exist "%MODEL_PATH%" set MODEL_PATH=%USERPROFILE%\.cache\geniex\models\unsloth\Qwen3-4B-Instruct-2507-GGUF\Qwen3-4B-Instruct-2507-Q4_0.gguf

rem Disabilita int dot / coopmat per compatibilita shader Adreno Vulkan
set GGML_VK_DISABLE_INTEGER_DOT_PRODUCT=1
set GGML_VK_DISABLE_COOPMAT=1

if not exist "%LLAMA_BIN%" (
    echo [ERRORE] llama-server.exe non trovato in: "%LLAMA_BIN%"
    pause
    exit /b 1
)

if not exist "%MODEL_PATH%" (
    echo [ERRORE] Modello Qwen3-4B non trovato. Scaricalo tramite: scripts\download_models.ps1
    pause
    exit /b 1
)

echo =========================================================================
echo  Avvio Server Qwen3-4B su http://127.0.0.1:18188/v1
echo  ID Modello   : Qwen3-4B-Adreno-GPU
echo  Acceleratore : Qualcomm Adreno GPU (Vulkan Nativo 1.85 GHz) + CPU Oryon
echo  Velocita     : ~50-75 tok/s (Chat Rapida, Reasoning Bilanciato)
echo  Origine      : Qualcomm AI Hub (https://aihub.qualcomm.com/models/qwen3_4b)
echo  Hardware     : Qualcomm Snapdragon X2 Elite Extreme (48GB UMA, 228 GB/s)
echo =========================================================================
echo.

"%LLAMA_BIN%" ^
  -m "%MODEL_PATH%" ^
  -ngl 99 ^
  --host 127.0.0.1 ^
  --port 18188 ^
  --alias "Qwen3-4B-Adreno-GPU" ^
  -c 65536 ^
  -np 1 ^
  -t 8 ^
  -lv 0

pause
