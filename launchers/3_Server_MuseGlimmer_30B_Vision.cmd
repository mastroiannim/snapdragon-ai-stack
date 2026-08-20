@echo off
title Server Muse Glimmer 30B Vision (Porta 18183) - GPU Adreno Vulkan
setlocal enabledelayedexpansion

set REPO_ROOT=%~dp0..
set LLAMA_BIN=%REPO_ROOT%\bin\llama-cpp-vulkan-arm64\llama-server.exe
if not exist "%LLAMA_BIN%" set LLAMA_BIN=%USERPROFILE%\bin\llama-cpp-vulkan-arm64\llama-server.exe

set MODEL_DIR=%REPO_ROOT%\models\Muse-Glimmer-30B
if not exist "%MODEL_DIR%" set MODEL_DIR=%USERPROFILE%\models\Muse-Glimmer-30B

rem Disabilita int dot / coopmat per compatibilita shader Adreno Vulkan
set GGML_VK_DISABLE_INTEGER_DOT_PRODUCT=1
set GGML_VK_DISABLE_COOPMAT=1

if not exist "%LLAMA_BIN%" (
    echo [ERRORE] llama-server.exe non trovato.
    pause
    exit /b 1
)

if not exist "%MODEL_DIR%\Muse-Glimmer-30B-Q4_K_M.gguf" (
    echo [ERRORE] Modello Muse Glimmer non trovato in: "%MODEL_DIR%"
    echo Scaricalo tramite: scripts\download_models.ps1
    pause
    exit /b 1
)

echo =========================================================================
echo  Avvio Server Muse Glimmer 30B su http://127.0.0.1:18183/v1
echo  ID Modello   : Muse-Glimmer-30B-Vision-GPU
echo  Funzionalita : Visione Multimodale (Immagini) + DFlash Speculative Decoding
echo  Acceleratore : Qualcomm Adreno GPU (Vulkan Nativo 1.85 GHz) + CPU Oryon
echo  Velocita     : ~14-20 tok/s con DFlash Speculative Decoding
echo  Hardware     : Qualcomm Snapdragon X2 Elite Extreme (228 GB/s)
echo =========================================================================
echo.

"%LLAMA_BIN%" ^
  -m "%MODEL_DIR%\Muse-Glimmer-30B-Q4_K_M.gguf" ^
  --mmproj "%MODEL_DIR%\mmproj-Muse-Glimmer-30B-f16.gguf" ^
  -ngl 99 ^
  --spec-type draft-dflash ^
  --spec-draft-model "%MODEL_DIR%\dflash-Muse-Glimmer-30B-Q4_0.gguf" ^
  --spec-draft-ngl 99 ^
  --spec-draft-n-max 16 ^
  --host 127.0.0.1 ^
  --port 18183 ^
  --alias "Muse-Glimmer-30B-Vision-GPU" ^
  -c 16384 ^
  -np 1 ^
  -t 8 ^
  -lv 0

pause