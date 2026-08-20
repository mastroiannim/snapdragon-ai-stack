# Architettura Hardware & Software: Snapdragon? X2 Elite Extreme AI Stack

## 1. Specifiche Hardware SoC (X2E94100)
- **SoC**: Qualcomm Snapdragon? X2 Elite Extreme X2E94100
- **Memoria Unificata (UMA)**: **48 GB LPDDR5x** con banda passante di **228 GB/s**
- **CPU**: **18 Core / 18 Thread Oryon di 3? Generazione** (53 MB Cache totale):
  - *Single-Core Boost*: fino a **4,7 GHz**
  - *Multi-Core Max*: fino a **4,4 GHz**
  - *Cluster Performance*: fino a **3,6 GHz**
- **GPU**: **Qualcomm Adreno X2-90** a **1,85 GHz**
- **NPU**: **Qualcomm Hexagon NPU** fino a **80 TOPS (INT8)**
- **I/O**: PCIe 5.0, NVMe, UFS 4.0, SD Express / SD 3.0, 3x USB 4.0

## 2. Stack Software Multi-Acceleratore
Il sistema sfrutta 3 percorsi paralleli di inferenza:
1. **Hexagon NPU Hub (Porta 18181)**: Motore QNN / HTP nativo a 80 TOPS (massima efficienza energetica, 4-8W, prefill a 837+ tok/s).
2. **Vulkan GPU Engine (Porte 18184 / 18185 / 18183)**: Runtime bare-metal Vulkan 1.4 su Adreno X2-90 a 1.85 GHz (massima velocita di decode, 24-35 tok/s).
3. **Caveman Fast Proxy (Porta 18182)**: Middleware Layer 7 che comprime i prompt di sistema (-98.8% token), azzera il TTFT e fornisce auto-fallback resiliente.