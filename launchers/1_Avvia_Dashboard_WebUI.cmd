@echo off
title Dashboard Open-WebUI (Porta 8080)
setlocal enabledelayedexpansion

echo =========================================================================
echo  Avvio Open-WebUI Dashboard su http://localhost:8080
echo  Funzione     : Interfaccia Chat Unificata (NPU, GPU, Vision, Proxy)
echo  Hardware     : Qualcomm Snapdragon X (ARM64 Windows)
echo =========================================================================
echo.

rem Tentativo di avvio tramite WSL2 o ambiente locale
where wsl >nul 2>&1
if %errorlevel% equ 0 (
    echo [INFO] Avvio Open-WebUI via WSL...
    start /B wsl -d Ubuntu bash -c "export DATA_DIR=~/.open-webui && export PORT=8080 && export WEBUI_AUTH=False && open-webui serve" >nul 2>&1
) else (
    echo [INFO] Avvio Open-WebUI via Python locale...
    start /B open-webui serve --port 8080 >nul 2>&1
)

echo.
echo Apertura del browser tra 3 secondi...
timeout /t 3 /nobreak >nul
start http://localhost:8080

echo.
echo Dashboard in esecuzione. Premi un tasto per arrestarla.
pause >nul