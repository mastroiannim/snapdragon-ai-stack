@echo off
title Server Phi-4-Mini-Instruct (Porta 18187) - GPU Adreno Vulkan
setlocal enabledelayedexpansion

set REPO_ROOT=%~dp0..
set LLAMA_BIN=%REPO_ROOT%\bin\llama-cpp-vulkan-arm64\llama-server.exe
if not exist "%LLAMA_BIN%" set LLAMA_BIN=%USERPROFILE%\bin\llama-cpp-vulkan-arm64\llama-server.exe

set MODEL_PATH=%REPO_ROOT%\models\Phi-4-mini-instruct\Phi-4-mini-instruct-Q4_K_M.gguf
if not exist "%MODEL_PATH%" set MODEL_PATH=%REPO_ROOT%\models\Phi-4-mini-instruct\Phi-4-mini-instruct-Q4_0.gguf
if not exist "%MODEL_PATH%" set MODEL_PATH=%USERPROFILE%\models\Phi-4-mini-instruct\Phi-4-mini-instruct-Q4_K_M.gguf
if not exist "%MODEL_PATH%" set MODEL_PATH=%USERPROFILE%\models\Phi-4-mini-instruct\Phi-4-mini-instruct-Q4_0.gguf
if not exist "%MODEL_PATH%" set MODEL_PATH=%USERPROFILE%\.cache\geniex\models\unsloth\Phi-4-mini-instruct-GGUF\Phi-4-mini-instruct-Q4_K_M.gguf
if not exist "%MODEL_PATH%" set MODEL_PATH=%USERPROFILE%\.cache\geniex\models\unsloth\Phi-4-mini-instruct-GGUF\Phi-4-mini-instruct-Q4_0.gguf

rem Disabilita int dot / coopmat per compatibilita shader Adreno Vulkan
set GGML_VK_DISABLE_INTEGER_DOT_PRODUCT=1
set GGML_VK_DISABLE_COOPMAT=1

if not exist "%LLAMA_BIN%" (
    echo [ERRORE] llama-server.exe non trovato in: "%LLAMA_BIN%"
    pause
    exit /b 1
)

if not exist "%MODEL_PATH%" (
    echo [ERRORE] Modello Phi-4-mini-instruct non trovato. Scaricalo tramite: scripts\download_models.ps1
    pause
    exit /b 1
)

echo =========================================================================
echo  Avvio Server Phi-4-Mini-Instruct su http://127.0.0.1:18187/v1
echo  ID Modello   : Phi-4-mini-instruct-Adreno-GPU
echo  Acceleratore : Qualcomm Adreno GPU (Vulkan Nativo 1.85 GHz) + CPU Oryon
echo  Velocita     : ~45-65 tok/s (Ragionamento Veloce, Logica, Coding)
echo  Origine      : Microsoft / Qualcomm AI Hub (aihub.qualcomm.com/models/phi_4_mini_instruct)
echo  Hardware     : Qualcomm Snapdragon X2 Elite Extreme (48GB UMA, 228 GB/s)
echo =========================================================================
echo.

"%LLAMA_BIN%" ^
  -m "%MODEL_PATH%" ^
  -ngl 99 ^
  --host 127.0.0.1 ^
  --port 18187 ^
  --alias "Phi-4-mini-instruct-Adreno-GPU" ^
  -c 16384 ^
  -np 4 ^
  -t 8 ^
  -lv 0

pause
