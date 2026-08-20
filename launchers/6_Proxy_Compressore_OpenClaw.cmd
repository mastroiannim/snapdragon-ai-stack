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
echo  Routing      : Invia a NPU (18181), GPU-27B (18184), GPU-8B (18185) e Vision (18183)
echo =========================================================================
echo.

node "%PROXY_SCRIPT%"

pause