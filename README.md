# ? Snapdragon AI Stack: Native ARM64 Local LLM Infrastructure

> **High-Performance Local AI Suite for Qualcomm Snapdragon X Elite / Extreme (Windows on ARM64)**  
> Sfrutta l'intero potenziale del SoC **Snapdragon? X2 Elite Extreme X2E94100** (48GB UMA, 228 GB/s, 18 Core Oryon a 4.7 GHz, GPU Adreno X2-90 a 1.85 GHz e NPU Hexagon a 80 TOPS).

---

## ?? Caratteristiche Principali

- ?? **Build Nativa ARM64 Vulkan 1.4 (ggml-vulkan)**: Eseguibili llama-server.exe, llama-bench.exe e llama-cli.exe compilati nativamente su Clang/LLVM 22 per Adreno X2-90 (fino a **35 tok/s** su 8B e **12 tok/s** su 27B).
- ?? **Hexagon NPU Hub (80 TOPS)**: Server locale su porta 18181 tramite QNN/HTP con prefill fulmineo a **837.6 tok/s** e consumo di soli **4W?8W**.
- ? **Caveman Fast Proxy (Porta 18182)**: Middleware intelligente Node.js che comprime i prompt di sistema del **98.8%** (da 3.400+ a ~40 token), azzera il Time-To-First-Token (TTFT < 80ms) e offre auto-fallback tra NPU e GPU.
- ??? **Multimodale + Speculative Decoding (Porta 18183)**: Supporto per visione (immagini/screenshot) con *Muse Glimmer 30B* e DFlash Speculative Decoding fino a **20 tok/s**.
- ?? **Dashboard Unificata Open-WebUI (Porta 8080)**: Interfaccia web per chattare con tutti i modelli locali.
- ?? **Compatibilit? Totale con VSCode Cline & OpenClaw**: Endpoint compatibili OpenAI /v1/chat/completions.

---

## ?? Matrice Prestazionale (Qwen3-8B su Snapdragon X2 Elite Extreme)

| Metrica | Vulkan Nativo (Adreno GPU) | Hexagon NPU (HTP 80 TOPS) | Caveman Proxy (Porta 18182) |
| :--- | :--- | :--- | :--- |
| **Prefill Speed** | 28.4 tok/s | **837.6 tok/s** | **Istantaneo (40 token)** |
| **Decode Speed** | **24 ? 35 tok/s** | 18 ? 25 tok/s | **24 ? 35 tok/s** |
| **Latenza TTFT (Prompt 3.500 tok)** | ~120 s | ~4.2 s | **? 0.08 s (80 ms)** |
| **Consumo Energetico** | 14W ? 20W | **4W ? 8W (Max autonomia)** | N/A (Middleware) |
| **Temperatura SoC** | ~46 ? 51 ?C | **~41 ? 44 ?C (Freddo)** | N/A |

---

## ??? Mappa Porte & Launcher Rapidi

| Porta | Servizio | Hardware | Scopo Consigliato |
| :--- | :--- | :--- | :--- |
| **18182** | 6_Proxy_Compressore_OpenClaw.cmd | Node.js Middleware | **Tutti i client (OpenClaw, WebUI, TTFT azzerato)** |
| **18181** | 2_Server_GenieX_NPU.cmd | Hexagon NPU (80 TOPS) | Grandi contesti, Coding RAG, Batteria |
| **18185** | 4_Server_Qwen8B_GPU.cmd | Adreno GPU (Vulkan 1.85 GHz) | Chat rapida, scrittura istantanea (~35 tok/s) |
| **18184** | 5_Server_Qwen27B_GPU.cmd | Adreno GPU (Vulkan 1.85 GHz) | Coding complesso in VSCode Cline (~12 tok/s) |
| **18183** | 3_Server_MuseGlimmer_30B_Vision.cmd | Adreno GPU (Vulkan + DFlash) | Visione multimodale (analisi immagini) |
| **8080** | 1_Avvia_Dashboard_WebUI.cmd | Browser Web | Interfaccia grafica unificata |

---

## ?? Quickstart: Come Iniziare

1. **Clona il repository**:
   `ash
   git clone https://github.com/tuo-username/snapdragon-ai-stack.git
   cd snapdragon-ai-stack
   `
2. **Scarica i modelli GGUF consigliati**:
   `powershell
   .\scripts\download_models.ps1
   `
3. **Avvia il server desiderato** dalla cartella launchers/ (ad esempio 4_Server_Qwen8B_GPU.cmd o 2_Server_GenieX_NPU.cmd).
4. **Avvia il Proxy e Open-WebUI** per iniziare a chattare immediatamente.

---

## ?? Struttura del Repository

`	ext
snapdragon-ai-stack/
??? launchers/       # Script di avvio rapidi portabili (.cmd)
??? proxy/           # Caveman Fast Proxy (Node.js)
??? bin/             # Binari ARM64 compilati (llama-server.exe, DLL)
??? configs/         # Template di configurazione (OpenClaw, Cline)
??? patches/         # Patch C++ per compilazione Win32 ARM64
??? scripts/         # Script PowerShell di automazione e build
??? docs/            # Documentazione approfondita (Architettura, Formule 228 GB/s, Benchmark)
??? .gitignore       # Esclusione automatica file pesanti (*.gguf, build/)
??? README.md
`

---

## ?? Licenza

Distribuito sotto licenza **MIT**. Consulta il file [LICENSE](LICENSE) per maggiori informazioni.