@echo off
title Dashboard Open-WebUI (Porta 8080)
setlocal enabledelayedexpansion

echo =========================================================================
echo  Avvio Open-WebUI Dashboard su http://localhost:8080
echo  Funzione     : Interfaccia Chat Unificata (NPU, GPU, Vision, Proxy)
echo  Hardware     : Qualcomm Snapdragon X (ARM64 Windows)
echo =========================================================================
echo.

rem Avvio ritardato dell'apertura del browser in background
start "" /B powershell -NoProfile -WindowStyle Hidden -Command "Start-Sleep -Seconds 4; Start-Process 'http://localhost:8080'"

rem Tentativo di avvio tramite WSL2 o ambiente locale
where wsl >nul 2>&1
if %errorlevel% equ 0 (
    echo [INFO] Rilevato WSL2. Avvio di Open-WebUI in ambiente Linux...
    echo [INFO] I log del server verranno mostrati in questa finestra.
    echo.
    wsl -d Ubuntu bash -c "export DATA_DIR=$HOME/.open-webui; export PORT=8080; export WEBUI_AUTH=False; export ENABLE_OPENAI_API=True; export ENABLE_OLLAMA_API=False; export OPENAI_API_BASE_URLS=\"http://127.0.0.1:18182/v1;http://127.0.0.1:18187/v1;http://127.0.0.1:18185/v1;http://127.0.0.1:18181/v1;http://127.0.0.1:18186/v1;http://127.0.0.1:18184/v1;http://127.0.0.1:18183/v1\"; export OPENAI_API_KEYS=\"none;none;none;none;none;none;none\"; if [ -f $HOME/open-webui-env/bin/open-webui ]; then exec $HOME/open-webui-env/bin/open-webui serve; elif [ -f $HOME/.local/bin/open-webui ]; then exec $HOME/.local/bin/open-webui serve; elif command -v open-webui >/dev/null 2>&1; then exec open-webui serve; else echo '[ERRORE] Open-WebUI non trovato in WSL Ubuntu.'; echo 'Installa con: pip install open-webui'; exit 1; fi"
    goto :end
)

where open-webui >nul 2>&1
if %errorlevel% equ 0 (
    echo [INFO] Avvio Open-WebUI via eseguibile Windows...
    set "OPENAI_API_BASE_URLS=http://127.0.0.1:18182/v1;http://127.0.0.1:18187/v1;http://127.0.0.1:18185/v1;http://127.0.0.1:18181/v1;http://127.0.0.1:18186/v1;http://127.0.0.1:18184/v1;http://127.0.0.1:18183/v1"
    set "OPENAI_API_KEYS=none;none;none;none;none;none;none"
    set "ENABLE_OLLAMA_API=False"
    open-webui serve --port 8080
    goto :end
)

where python >nul 2>&1
if %errorlevel% equ 0 (
    echo [INFO] Tentativo di avvio Open-WebUI via Python locale...
    set "OPENAI_API_BASE_URLS=http://127.0.0.1:18182/v1;http://127.0.0.1:18187/v1;http://127.0.0.1:18185/v1;http://127.0.0.1:18181/v1;http://127.0.0.1:18186/v1;http://127.0.0.1:18184/v1;http://127.0.0.1:18183/v1"
    set "OPENAI_API_KEYS=none;none;none;none;none;none;none"
    set "ENABLE_OLLAMA_API=False"
    python -m open_webui serve --port 8080
    if %errorlevel% neq 0 (
        echo [ERRORE] Impossibile avviare Open-WebUI tramite Python locale.
    )
    goto :end
)

echo [ERRORE] Open-WebUI o WSL2 non trovati nel sistema.
echo Consulta la documentazione nel README.md per i dettagli di installazione.

:end
echo.
pause