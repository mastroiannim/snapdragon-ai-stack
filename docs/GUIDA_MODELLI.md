================================================================================
          SUITE MODELLI AI LOCALI - SNAPDRAGON X2 ELITE EXTREME (X2E94100)
================================================================================

Questa cartella contiene gli script organizzati e numerati per gestire tutti
i modelli AI, i server locali e le dashboard su Snapdragon? X2 Elite Extreme X2E94100:
* 48 GB Unified Memory (UMA) LPDDR5x con larghezza di banda di 228 GB/s
* 18 Cores / 18 Threads Oryon Gen3 (53 MB Cache, Boost 4.7 GHz, All-core 4.4 GHz)
* GPU Qualcomm Adreno X2-90 a 1.85 GHz (Vulkan 1.4 Nativo)
* NPU Qualcomm Hexagon HTP fino a 80 TOPS (INT8)

--------------------------------------------------------------------------------
1. MAPPA DELLE PORTE, SERVER E VELOCIT? MISURATE
--------------------------------------------------------------------------------

[Porta 18181] -> GenieX NPU Hub (Hexagon NPU - fino a 80 TOPS)
                 * Modello 8B  : unsloth/Qwen3-8B-128K-GGUF:Q4_0
                   - Prefill Prompt : ~837 tok/s (Ingestione istantanea)
                   - Decode Output  : ~18 - 25 tok/s (Max efficienza, 4-8W)
                 * Modello 27B : IvanKrastevAdventics/Qwen3.8-27B-AWQ-INT4:Q4_0
                   - Prefill Prompt : ~105 tok/s
                   - Decode Output  : ~5 - 8 tok/s

[Porta 18182] -> Caveman Fast Proxy (Compressore Ultra-Fast)
                 * Comprime prompt da 3.400+ token a ~40 token
                 * Elimina i monologhi interni difettosi (<think>)
                 * Espone varianti "(Caveman Fast)" per NPU e GPU

[Porta 18183] -> Muse Glimmer 30B Vision (GPU Adreno Vulkan + Speculative Decoding)
                 * ID Modello : Muse-Glimmer-30B-Vision-GPU
                 * Supporta immagini/screenshot (Visione multimodale)
                 * Velocita   : ~14 - 20 tok/s (grazie a DFlash Speculative Decoding)

[Porta 18184] -> Qwen3.8 27B GPU (Qualcomm Adreno X2-90 Vulkan Nativo)
                 * ID Modello : Qwen3.8-27B-Adreno-GPU
                 * Ingestione : ~315 tok/s
                 * Generazione: ~8 - 12 tok/s (Limite teorico banda 228 GB/s = 15 tok/s)
                 * Scelta ideale per VSCode + Cline (Coding Complesso)

[Porta 18185] -> Qwen3 8B GPU (Qualcomm Adreno X2-90 Vulkan Nativo)
                 * ID Modello : Qwen3-8B-Adreno-GPU
                 * Scrittura  : ~24 - 35 tok/s (Scrittura fluida a schermo)
                 * Scelta ideale per risposte fulminee e chat veloci

[Porta 18186] -> Gemma 4 31B GPU (Qualcomm Adreno X2-90 Vulkan Nativo)
                 * ID Modello : Gemma-4-31B-Adreno-GPU
                 * Ingestione : ~260 tok/s
                 * Generazione: ~6 - 9 tok/s (Limite teorico banda 228 GB/s = 12.3 tok/s)
                 * Modello QAT (Quantization-Aware Training) per massima precisione in 4-bit

[Porta 18187] -> Phi-4-Mini-Instruct GPU (Qualcomm Adreno X2-90 Vulkan Nativo / AI Hub)
                 * ID Modello : Phi-4-mini-instruct-Adreno-GPU
                 * Sorgente   : Microsoft / Qualcomm AI Hub (aihub.qualcomm.com/models/phi_4_mini_instruct)
                 * Ingestione : ~450 tok/s su GPU (>1.200 tok/s su NPU 80 TOPS)
                 * Generazione: ~45 - 65 tok/s (Fluido, Istantaneo)
                 * Uso        : Logica Matematica, Reasoning Veloce, Assistente Coding Compatto

[Porta 8080]  -> Open-WebUI Dashboard
                 * Interfaccia chat unificata nel browser (http://localhost:8080)

--------------------------------------------------------------------------------
2. CALCOLI TEORICI ED EFFETTIVI SULLA BANDA DI MEMORIA (228 GB/s)
--------------------------------------------------------------------------------

Il limite fisico fondamentale nella generazione token-by-token (Decode) dei LLM
? memory-bound: ogni token generato richiede la lettura sequenziale dell'intero
modello dalla memoria RAM.

Formula del limite teorico:
  Throughput Massimo (tok/s) = Banda Memoria (GB/s) / Dimensione Modello (GB)

1. MODELLO 8B (Q4_0 - 4.45 GiB in RAM):
   - Limite teorico assoluto : 228 GB/s / 4.5 GB = 50.6 tok/s
   - Efficienza reale (50-70%): ~24 - 35 tok/s su GPU Vulkan (~18-25 tok/s su NPU)
   - Prefill (Compute-bound) : Fino a 837.6 tok/s su NPU Hexagon 80 TOPS!

2. MODELLO 27B (AWQ INT4 Q4_0 - 15.2 GiB in RAM):
   - Limite teorico assoluto : 228 GB/s / 15.2 GB = 15.0 tok/s
   - Efficienza reale (55-75%): ~8 - 12 tok/s su GPU Vulkan (~5-8 tok/s su NPU)
   - Prefill (Compute-bound) : ~105 - 315 tok/s

3. MODELLO 30B VISION (Q4_K_M - 18.5 GiB in RAM):
   - Limite autoregressivo   : 228 GB/s / 18.5 GB = 12.3 tok/s teorici (~7 tok/s reale)
   - Con Speculative DFlash  : ~14 - 20 tok/s effettivi (elaborazione multi-token per fetch)

4. MODELLO GEMMA 4 31B (Q4_0 - 18.5 GiB in RAM):
   - Limite teorico assoluto : 228 GB/s / 18.5 GB = 12.3 tok/s
   - Efficienza reale (50-70%): ~6 - 9 tok/s su GPU Vulkan
   - Prefill (Compute-bound) : ~260 tok/s su GPU Vulkan (grazie all'ottimizzazione degli shader)

5. MODELLO PHI-4-MINI-INSTRUCT (Q4_K_M / Q4_0 - 2.4 GiB in RAM):
   - Limite teorico assoluto : 228 GB/s / 2.4 GB = 95.0 tok/s
   - Benchmark Ufficiale AI Hub su NPU : 1.276 tok/s Prefill • 18.1 tok/s Decode (HTP 80 TOPS)
   - Prestazioni su Adreno GPU Vulkan  : ~45 - 65 tok/s Decode • ~450 tok/s Prefill
   - Caratteristiche                   : Modello compatto da 3.8B (Microsoft / Qualcomm AI Hub) con altissimi punteggi in ragionamento, logica matematica e coding compatto.

--------------------------------------------------------------------------------
3. ELENCO DEGLI SCRIPT DI AVVIO
--------------------------------------------------------------------------------

[1] 1_Avvia_Dashboard_WebUI.cmd
    -> Avvia Open-WebUI in WSL e apre automaticamente il browser su http://localhost:8080.

[2] 2_Server_GenieX_NPU.cmd
    -> Avvia il server GenieX su porta 18181 (massima efficienza energetica su NPU 80 TOPS).

[3] 3_Server_MuseGlimmer_30B_Vision.cmd
    -> Avvia il server multimodale da 30B con supporto immagini su porta 18183.

[4] 4_Server_Qwen8B_GPU.cmd
    -> Avvia Qwen 8B su porta 18185 con GPU Adreno Vulkan (velocita estrema ~25-35 tok/s).

[5] 5_Server_Qwen27B_GPU.cmd
    -> Avvia Qwen 27B su porta 18184 con GPU Adreno Vulkan (max intelligenza e coding).

[6] 6_Proxy_Compressore_OpenClaw.cmd
    -> Avvia il proxy intelligente su porta 18182 che accelera OpenClaw e Open-WebUI.

[7] 7_Server_Gemma31B_GPU.cmd
    -> Avvia Gemma 4 31B su porta 18186 con GPU Adreno Vulkan (ragionamento avanzato e coding).

[8] 8_Server_Phi4Mini_GPU.cmd
    -> Avvia Phi-4-Mini-Instruct su porta 18187 con GPU Adreno Vulkan (ragionamento veloce ~45-65 tok/s).

[9] Stop_Tutti_I_Server.cmd
    -> Chiude tutti i processi (GenieX, llama-server, Proxy Node) con un clic,
       liberando istantaneamente RAM, VRAM e NPU.

--------------------------------------------------------------------------------
4. COME CONFIGURARE CLINE IN VSCODE
--------------------------------------------------------------------------------

1. Avvia lo script desiderato:
   - Per Reasoning Veloce e Coding Leggero : 8_Server_Phi4Mini_GPU.cmd (Porta 18187)
   - Per Ragionamento e Coding Avanzato   : 7_Server_Gemma31B_GPU.cmd (Porta 18186)
   - Per Coding Complesso                 : 5_Server_Qwen27B_GPU.cmd (Porta 18184)
   - Per Velocita Estrema                 : 4_Server_Qwen8B_GPU.cmd   (Porta 18185)

2. In VSCode apri le Impostazioni di Cline (icona ingranaggio).
3. Imposta i parametri:
   - API Provider : OpenAI Compatible
   - Base URL     : http://127.0.0.1:18187/v1 (o 18186/v1, 18184/v1, 18185/v1)
   - API Key      : local
   - Model ID     : Phi-4-mini-instruct-Adreno-GPU (o Gemma-4-31B-Adreno-GPU / Qwen3.8-27B-Adreno-GPU / Qwen3-8B-Adreno-GPU)
================================================================================