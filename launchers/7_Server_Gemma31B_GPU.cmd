@echo off
title Server Gemma 4 31B (Porta 18186) - GPU Adreno Vulkan
setlocal enabledelayedexpansion

set REPO_ROOT=%~dp0..
set LLAMA_BIN=%REPO_ROOT%\bin\llama-cpp-vulkan-arm64\llama-server.exe
if not exist "%LLAMA_BIN%" set LLAMA_BIN=%USERPROFILE%\bin\llama-cpp-vulkan-arm64\llama-server.exe

set MODEL_PATH=%REPO_ROOT%\models\Gemma-4-31B\gemma-4-31b-it-qat-q4_0.gguf
if not exist "%MODEL_PATH%" set MODEL_PATH=%REPO_ROOT%\models\Gemma-4-31B\gemma-4-31B_q4_0-it.gguf
if not exist "%MODEL_PATH%" set MODEL_PATH=%USERPROFILE%\models\Gemma-4-31B\gemma-4-31b-it-qat-q4_0.gguf
if not exist "%MODEL_PATH%" set MODEL_PATH=%USERPROFILE%\models\Gemma-4-31B\gemma-4-31B_q4_0-it.gguf
if not exist "%MODEL_PATH%" set MODEL_PATH=%USERPROFILE%\.cache\geniex\models\google\gemma-4-31B-it-qat-q4_0-gguf\gemma-4-31b-it-qat-q4_0.gguf
if not exist "%MODEL_PATH%" set MODEL_PATH=%USERPROFILE%\.cache\geniex\models\google\gemma-4-31B-it-qat-q4_0-gguf\gemma-4-31B_q4_0-it.gguf

rem Disabilita int dot / coopmat per compatibilita shader Adreno Vulkan
set GGML_VK_DISABLE_INTEGER_DOT_PRODUCT=1
set GGML_VK_DISABLE_COOPMAT=1

if not exist "%LLAMA_BIN%" (
    echo [ERRORE] llama-server.exe non trovato in: "%LLAMA_BIN%"
    pause
    exit /b 1
)

if not exist "%MODEL_PATH%" (
    echo [ERRORE] Modello Gemma 4 31B non trovato. Scaricalo tramite: scripts\download_models.ps1
    pause
    exit /b 1
)

echo =========================================================================
echo  Avvio Server Gemma-4-31B su http://127.0.0.1:18186/v1
echo  ID Modello   : Gemma-4-31B-Adreno-GPU
echo  Acceleratore : Qualcomm Adreno GPU (Vulkan Nativo 1.85 GHz) + CPU Oryon
echo  Velocita     : ~260 tok/s Ingestione Codice - ~6-9 tok/s Generazione
echo  Uso Target   : VSCode + Cline, Ragionamento Complesso e Coding
echo  Hardware     : Qualcomm Snapdragon X2 Elite Extreme (48GB UMA, 228 GB/s)
echo =========================================================================
echo.

"%LLAMA_BIN%" ^
  -m "%MODEL_PATH%" ^
  -ngl 99 ^
  --host 127.0.0.1 ^
  --port 18186 ^
  --alias "Gemma-4-31B-Adreno-GPU" ^
  -c 16384 ^
  -np 1 ^
  -t 8 ^
  -lv 0

pause
