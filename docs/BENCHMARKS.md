# Benchmark e Analisi Prestazionale a 7 Dimensioni

Test condotti con modello standard **unsloth/Qwen3-8B-128K-GGUF (Q4_0, 4.45 GiB)** su **Snapdragon X2 Elite Extreme (228 GB/s)**.

| Parametro / Metrica | Vulkan Nativo (Adreno GPU) | OpenCL (Adreno GPU) | Hexagon NPU (HTP0 QNN) | Vincitore Assoluto |
| :--- | :--- | :--- | :--- | :--- |
| **1. Prefill Throughput** *(Prompt 670 tok)* | **28.4 tok/s** | **315.5 tok/s** | **837.6 tok/s** | ?? **Hexagon NPU** *(+165% vs OpenCL)* |
| **2. Decode Throughput** *(Generazione 64 tok)* | **22.2 ? 23.9 tok/s** | **18.8 ? 19.3 tok/s** | **17.0 ? 19.3 tok/s** | ?? **Vulkan GPU** *(+18% vs OpenCL, +30% vs NPU)* |
| **3. Latenza TTFT** *(Time to First Token - 670 tok)* | 23.50 s | 2.12 s | **0.80 s (800 ms)** | ?? **Hexagon NPU** *(Quasi istantaneo)* |
| **4. Latenza per Token** *(Decode ms/tok)* | **45.0 ms / tok** | 53.2 ms / tok | 58.9 ms / tok | ?? **Vulkan GPU** *(Streaming piu rapido)* |
| **5. Occupazione Memoria** *(RAM/VRAM)* | ~5.4 ? 5.8 GB | ~5.4 GB | **~4.8 GB** | ?? **Hexagon NPU** *(Zero overhead DMA)* |
| **6. Temperatura SoC** *(Carico 100%)* | ~46 ? 51 ?C | ~48 ? 53 ?C | **~41 ? 44 ?C** | ?? **Hexagon NPU** *(Completamente freddo)* |
| **7. Consumo Energetico Stimato** | ~14W ? 20W | ~18W ? 25W | **~4W ? 8W** | ?? **Hexagon NPU** *(Autonomia 6-8h+)* |
| **8. HTP Utilizzati** | N/A (GPU Compute) | N/A (GPU OpenCL) | **HTP0 (HVX/HMX v75/v79/v81 - 80 TOPS)** | ?? **Hexagon NPU** |

## Benchmark Caveman Fast Proxy (Middleware di Compressione)

| Metrica | Senza Caveman (Prompt Raw) | Con Caveman Proxy (Porta 18182) | Guadagno |
| :--- | :--- | :--- | :--- |
| **Risparmio KV Cache RAM** | 3.5 GB | **0.1 GB** | **Risparmio ~3.4 GB RAM** |

---

## Panoramica Comparativa Modelli (Snapdragon X2 Elite Extreme - 228 GB/s)

| Modello | Dimensione (Q4) | Vulkan GPU Decode | Hexagon NPU Decode | Hexagon NPU Prefill | Consumo NPU vs GPU |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Phi-4-Mini-Instruct (3.8B)** | ~2.49 GB | ~45 – 65 tok/s | ~18.1 tok/s | **~1.276 tok/s** | 4W–8W vs 14W–18W |
| **Gemma-4-E2B-it (2.3B QAT)** | ~3.04 GB | **~65 – 90 tok/s** | **~35.1 tok/s** | **~1.808 tok/s** | 4W–8W vs 12W–16W |
| **Qwen3-4B-Instruct (4B)** | ~2.55 GB | **~50 – 75 tok/s** | ~20 – 28 tok/s | **~1.100+ tok/s** | 4W–8W vs 14W–18W |
| **Qwen3-8B-128K (8B)** | ~4.45 GB | ~24 – 35 tok/s | ~18 – 25 tok/s | **~837 tok/s** | 4W–8W vs 14W–20W |
| **Qwen3.8-27B (27B)** | ~15.2 GB | ~8 – 12 tok/s | ~5 – 8 tok/s | ~105 tok/s | 6W–10W vs 18W–24W |
| **Muse-Glimmer-30B (Vision)** | ~16.1 GB | ~14 – 20 tok/s (DFlash) | N/A | ~260 tok/s | 18W–25W |
| **Gemma-4-31B-it (31B QAT)** | ~18.5 GB | ~6 – 9 tok/s | N/A | ~260 tok/s | 18W–25W |