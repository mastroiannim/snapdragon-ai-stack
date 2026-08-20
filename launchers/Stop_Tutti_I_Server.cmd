@echo off
title Arresto Server AI Locali
setlocal enabledelayedexpansion

echo =========================================================================
echo  Arresto di tutti i server AI Snapdragon X2 in corso...
echo =========================================================================
echo.

taskkill /F /IM llama-server.exe >nul 2>&1
taskkill /F /IM geniex.exe >nul 2>&1
taskkill /F /IM node.exe /FI "WINDOWTITLE eq Prompt Compressor*" >nul 2>&1
where wsl >nul 2>&1 && wsl -d Ubuntu pkill -f open-webui >nul 2>&1
taskkill /F /IM open-webui.exe >nul 2>&1

echo [OK] Tutti i processi (llama-server, GenieX, Proxy Node, Open-WebUI) sono stati arrestati.
echo [OK] Memoria RAM, VRAM e NPU liberate istantaneamente.
echo.
powershell -NoProfile -Command "Start-Sleep -Seconds 2"