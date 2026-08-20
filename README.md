# ⚡ Snapdragon AI Stack: Native ARM64 Local LLM Infrastructure

> **High-Performance Local AI Suite for Qualcomm Snapdragon X Elite / Extreme (Windows on ARM64)**  
> Sfrutta l'intero potenziale del SoC **Snapdragon® X2 Elite Extreme X2E94100** (48GB UMA, 228 GB/s, 18 Core Oryon a 4.7 GHz, GPU Adreno X2-90 a 1.85 GHz e NPU Hexagon a 80 TOPS).

---

## 🌟 Caratteristiche Principali

- 🚀 **Motori di Inferenza Nativa ARM64 Completi (in/)**:
  - **llama-cpp-vulkan-arm64**: Backend Vulkan 1.4 bare-metal per Adreno GPU (fino a **35 tok/s** su 8B e **12 tok/s** su 27B).
  - **llama-cpp-hexagon-arm64**: Backend Hexagon NPU con runtime QAIRT / QNN v75/v79/v81 (ggml-hexagon.dll, HTP libraries).
  - **llama-cpp-adreno-arm64**: Backend GPU OpenCL legacy (ggml-opencl.dll).
  - **llama-cpp-arm64**: Backend CPU multi-thread nativo Oryon ARM64.
- 🧠 **Hexagon NPU Hub (80 TOPS)**: Server locale su porta 18181 tramite QNN/HTP con prefill fulmineo a **837.6 tok/s** e consumo di soli **4W–8W**.
- ⚡ **Caveman Fast Proxy (Porta 18182)**: Middleware intelligente Node.js che comprime i prompt di sistema del **98.8%** (da 3.400+ a ~40 token), azzera il Time-To-First-Token (TTFT < 80ms) e offre auto-fallback tra NPU e GPU.
- 👁️ **Multimodale + Speculative Decoding (Porta 18183)**: Supporto per visione (immagini/screenshot) con *Muse Glimmer 30B* e DFlash Speculative Decoding fino a **20 tok/s**.
- 🌐 **Dashboard Unificata Open-WebUI (Porta 8080)**: Interfaccia web per chattare con tutti i modelli locali.
- 🔌 **Compatibilità Totale con VSCode Cline & OpenClaw**: Endpoint compatibili OpenAI /v1/chat/completions.
- 🛠️ **Toolchain e SDK di Build Inclusi (sdk/ e scripts/)**: Header Vulkan e SPIR-V ufficiali Khronos, librerie d'importazione libvulkan-1.a, patch C++ e script di compilazione automatizzati con Clang/LLVM 22 ARM64.

---

## 📊 Matrice Prestazionale (Qwen3-8B su Snapdragon X2 Elite Extreme)

| Metrica | Vulkan Nativo (Adreno GPU) | Hexagon NPU (HTP 80 TOPS) | Caveman Proxy (Porta 18182) |
| :--- | :--- | :--- | :--- |
| **Prefill Speed** | 28.4 tok/s | **837.6 tok/s** | **Istantaneo (40 token)** |
| **Decode Speed** | **24 – 35 tok/s** | 18 – 25 tok/s | **24 – 35 tok/s** |
| **Latenza TTFT (Prompt 3.500 tok)** | ~120 s | ~4.2 s | **⚡ 0.08 s (80 ms)** |
| **Consumo Energetico** | 14W – 20W | **4W – 8W (Max autonomia)** | N/A (Middleware) |
| **Temperatura SoC** | ~46 – 51 °C | **~41 – 44 °C (Freddo)** | N/A |

---

## 🗺️ Mappa Porte & Launcher Rapidi

| Porta | Servizio | Hardware | Scopo Consigliato |
| :--- | :--- | :--- | :--- |
| **18182** | 6_Proxy_Compressore_OpenClaw.cmd | Node.js Middleware | **Tutti i client (OpenClaw, WebUI, TTFT azzerato)** |
| **18181** | 2_Server_GenieX_NPU.cmd | Hexagon NPU (80 TOPS) | Grandi contesti, Coding RAG, Batteria |
| **18185** | 4_Server_Qwen8B_GPU.cmd | Adreno GPU (Vulkan 1.85 GHz) | Chat rapida, scrittura istantanea (~35 tok/s) |
| **18184** | 5_Server_Qwen27B_GPU.cmd | Adreno GPU (Vulkan 1.85 GHz) | Coding complesso in VSCode Cline (~12 tok/s) |
| **18183** | 3_Server_MuseGlimmer_30B_Vision.cmd | Adreno GPU (Vulkan + DFlash) | Visione multimodale (analisi immagini) |
| **8080** | 1_Avvia_Dashboard_WebUI.cmd | Browser Web | Interfaccia grafica unificata |

---

## 📋 Prerequisiti di Sistema

Prima di iniziare, assicurati di avere installato:

1. **Sistema Operativo**: Windows 11 on ARM64 (Snapdragon X Elite / Plus / Extreme).
2. **WSL2 (Windows Subsystem for Linux)**: Necessario per eseguire Open-WebUI in ambiente Linux isolato e ultra-stabile:
   ```powershell
   wsl --install -d Ubuntu
   ```
   *All'interno del terminale WSL Ubuntu, crea l'ambiente virtuale dedicato e installa Open-WebUI:*
   ```bash
   sudo apt update && sudo apt install -y python3-pip python3-venv
   python3 -m venv ~/open-webui-env
   ~/open-webui-env/bin/pip install open-webui
   ```
3. **Node.js (LTS v20+ o v22+ ARM64)**: Necessario per il runtime del *Caveman Fast Proxy* (porta 18182).
   - Scaricabile da [nodejs.org](https://nodejs.org).
4. **GenieX CLI (Opzionale per NPU)**:
   - Scaricabile da [geniex.ai](https://geniex.ai) per abilitare il backend Hexagon NPU a 80 TOPS.
5. **Driver Qualcomm Adreno GPU**: Già inclusi nel sistema Windows 11 ARM64 (C:\Windows\System32\vulkan-1.dll).

---

## 🚀 Quickstart: Come Iniziare

### 1. Clona il repository
`ash
git clone https://github.com/tuo-username/snapdragon-ai-stack.git
cd snapdragon-ai-stack
`

### 2. Configura il Networking WSL2 (Mirrored Mode)
Per consentire a Open-WebUI (in esecuzione su WSL2) di connettersi ai server NPU/GPU di Windows su 127.0.0.1 senza blocchi di rete:
`powershell
Copy-Item configs\wslconfig.template "C:\Users\mstmh\.wslconfig" -Force
wsl --shutdown
`

### 3. Scarica i Modelli GGUF
Scarica i modelli quantizzati ottimizzati per l'architettura Snapdragon:
`powershell
.\scripts\download_models.ps1
`

### 4. Avvia i Server e Inizia a Chattare
Dalla cartella launchers/ puoi avviare con un doppio clic:
1. **2_Server_GenieX_NPU.cmd** (per NPU 80 TOPS) oppure **4_Server_Qwen8B_GPU.cmd** (per GPU Vulkan).
2. **6_Proxy_Compressore_OpenClaw.cmd** (per azzerare il TTFT e comprimere i prompt).
3. **1_Avvia_Dashboard_WebUI.cmd** (per aprire l'interfaccia nel browser su http://localhost:8080).

---

## 📂 Struttura del Repository

`	ext
snapdragon-ai-stack/
├── launchers/       # Script di avvio rapidi portabili (.cmd)
├── proxy/           # Caveman Fast Proxy (Node.js)
├── bin/             # Motori di inferenza compilati (Vulkan, Hexagon NPU, Adreno OpenCL, CPU)
├── sdk/             # Vulkan-Headers, SPIRV-Headers e librerie d'importazione libvulkan-1.a
├── configs/         # Template di configurazione (OpenClaw, Cline, .wslconfig)
├── patches/         # Patch C++ per compilazione Win32 ARM64
├── scripts/         # Script PowerShell di automazione, setup toolchain e build
├── docs/            # Documentazione approfondita (Architettura, Formule 228 GB/s, Benchmark)
├── .gitignore       # Esclusione automatica file pesanti (*.gguf, build/)
└── README.md
`

---

## 📄 Licenza

Distribuito sotto licenza **MIT**. Consulta il file [LICENSE](LICENSE) per maggiori informazioni.