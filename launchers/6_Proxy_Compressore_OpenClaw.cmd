@echo off
title Prompt Compressor Proxy (Porta 18182) - Compressione OpenClaw Ultra-Fast
setlocal enabledelayedexpansion

set REPO_ROOT=%~dp0..
set PROXY_SCRIPT=%REPO_ROOT%\proxy\caveman-proxy.mjs
if not exist "%PROXY_SCRIPT%" set PROXY_SCRIPT=%USERPROFILE%\.openclaw\caveman-proxy.mjs

echo =========================================================================
echo  Avvio Caveman Fast Proxy su http://127.0.0.1:18182/v1
echo  Funzione     : Compressione System Prompt (da 3.400+ a ~40 token, -98.8%)
echo  Features     : Anti-tag reasoning, TTFT quasi azzerato (0.05s)
echo  Routing      : 
echo    * NPU (18181)       -> Hexagon NPU (Phi-4 Mini 3.8B, Qwen 8B, Qwen 27B)
echo    * GPU-Phi4 (18187)  -> Adreno GPU (Phi-4 Mini 3.8B Vulkan, ~45-65 tok/s)
echo    * GPU-Gemma (18186) -> Adreno GPU (Gemma 4 31B Vulkan, ~6-9 tok/s)
echo    * GPU-8B (18185)    -> Adreno GPU (Qwen3 8B Vulkan, ~24-35 tok/s)
echo    * GPU-27B (18184)   -> Adreno GPU (Qwen3.8 27B Vulkan, ~8-12 tok/s)
echo    * Vision (18183)    -> Adreno GPU (Muse Glimmer 30B Multimodale)
echo =========================================================================
echo.

node "%PROXY_SCRIPT%"

pause