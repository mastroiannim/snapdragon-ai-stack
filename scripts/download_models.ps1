# download_models.ps1
# Script per scaricare e predisporre i modelli GGUF ottimizzati per Snapdragon X tramite CLI 'hf' o GenieX
# Supporta sincronizzazione automatica HardLink NTFS per NPU (GenieX) e GPU (Adreno Vulkan) a 0 byte aggiuntivi.

param (
    [string]$ModelName = "",
    [switch]$All,
    [switch]$MissingOnly,
    [switch]$SyncLinks,
    [switch]$NonInteractive
)

$RepoRoot = Split-Path $PSScriptRoot -Parent
$ModelsDir = Join-Path $RepoRoot "models"

# Definizione dei modelli supportati
$ModelDefinitions = @(
    @{
        Key = "1"
        Id = "qwen8b"
        Name = "Qwen3-8B-128K (4.45 GB)"
        Repo = "unsloth/Qwen3-8B-128K-GGUF"
        File = "Qwen3-8B-128K-Q4_0.gguf"
        TargetDir = Join-Path $ModelsDir "Qwen3-8B"
        NpuSupport = $true
        Description = "Chat rapida, scrittura fluida (~35 tok/s) o Hexagon NPU"
    },
    @{
        Key = "2"
        Id = "qwen27b"
        Name = "Qwen3.8-27B AWQ (15.2 GB)"
        Repo = "IvanKrastevAdventics/Qwen3.8-27B-AWQ-INT4-Q4_0-GGUF"
        File = "qwen3.8-27b-awq-int4-q4_0.gguf"
        TargetDir = Join-Path $ModelsDir "Qwen3.8-27B"
        NpuSupport = $true
        Description = "Coding complesso in VSCode Cline (~12 tok/s)"
    },
    @{
        Key = "3"
        Id = "muse30b"
        Name = "Muse-Glimmer-30B Vision (16.1 GB)"
        Repo = "unsloth/Muse-Glimmer-30B-GGUF"
        File = "Muse-Glimmer-30B-Q4_K_M.gguf"
        ExtraFiles = @("mmproj-Muse-Glimmer-30B-f16.gguf", "dflash-Muse-Glimmer-30B-Q4_0.gguf")
        TargetDir = Join-Path $ModelsDir "Muse-Glimmer-30B"
        NpuSupport = $false
        Description = "Visione multimodale + Speculative DFlash (~20 tok/s)"
    },
    @{
        Key = "4"
        Id = "gemma31b"
        Name = "Gemma-4-31B-it QAT (18.5 GB)"
        Repo = "google/gemma-4-31B-it-qat-q4_0-gguf"
        File = "gemma-4-31B_q4_0-it.gguf"
        AltFiles = @("gemma-4-31b-it-qat-q4_0.gguf")
        TargetDir = Join-Path $ModelsDir "Gemma-4-31B"
        NpuSupport = $false
        Description = "Ragionamento avanzato e coding multi-step (~6-9 tok/s)"
    },
    @{
        Key = "5"
        Id = "phi4mini"
        Name = "Phi-4-Mini-Instruct (2.49 GB - Qualcomm AI Hub)"
        Repo = "unsloth/Phi-4-mini-instruct-GGUF"
        File = "Phi-4-mini-instruct-Q4_K_M.gguf"
        AltFiles = @("Phi-4-mini-instruct-Q4_0.gguf")
        TargetDir = Join-Path $ModelsDir "Phi-4-mini-instruct"
        NpuSupport = $true
        Description = "Logica matematica, reasoning veloce (~45-65 tok/s GPU / >1200 NPU)"
    },
    @{
        Key = "6"
        Id = "qwen4b"
        Name = "Qwen3-4B-Instruct (2.55 GB - Qualcomm AI Hub)"
        Repo = "unsloth/Qwen3-4B-Instruct-2507-GGUF"
        File = "Qwen3-4B-Instruct-2507-Q4_K_M.gguf"
        AltFiles = @("Qwen3-4B-Q4_K_M.gguf", "Qwen3-4B-Q4_0.gguf")
        TargetDir = Join-Path $ModelsDir "Qwen3-4B"
        NpuSupport = $true
        Description = "Chat e reasoning bilanciato (~50-75 tok/s GPU / >1100 NPU)"
    },
    @{
        Key = "7"
        Id = "gemma4e2b"
        Name = "Gemma-4-E2B-it QAT (3.04 GB - Qualcomm AI Hub)"
        Repo = "google/gemma-4-E2B-it-qat-q4_0-gguf"
        File = "gemma-4-E2B_q4_0-it.gguf"
        AltFiles = @("gemma-4-E2B-it-qat-UD-Q4_K_XL.gguf", "gemma-4-e2b-it-qat-q4_0.gguf")
        TargetDir = Join-Path $ModelsDir "Gemma-4-E2B"
        NpuSupport = $true
        Description = "Multimodale, NPU Hexagon (~35.1 tok/s decode, ~1808 tok/s prefill) o GPU (~65-90 tok/s)"
    }
)

function Sync-ModelHardlink {
    param ($mDef)
    $localFile = Join-Path $mDef.TargetDir $mDef.File
    $geniexDir = Join-Path $env:USERPROFILE ".cache\geniex\models\$($mDef.Repo)"
    $geniexFile = Join-Path $geniexDir $mDef.File

    # 1. Se presente nella cache di GenieX ma mancante in models/ -> crea HardLink in models/
    if ((Test-Path $geniexFile) -and (-not (Test-Path $localFile))) {
        New-Item -ItemType Directory -Path $mDef.TargetDir -Force | Out-Null
        try {
            New-Item -ItemType HardLink -Path $localFile -Target $geniexFile -ErrorAction Stop | Out-Null
            Write-Host "  [LINK] Hardlink creato: models\$($mDef.TargetDir | Split-Path -Leaf)\$($mDef.File) <-> GenieX cache" -ForegroundColor DarkCyan
        } catch {
            Write-Host "  [WARN] Impossibile creare hardlink per $($mDef.Name): $_" -ForegroundColor Yellow
        }
    }

    # 2. Se presente in models/ ma mancante in GenieX (ed e supportato da NPU) -> crea HardLink in GenieX
    if ((Test-Path $localFile) -and (-not (Test-Path $geniexFile)) -and $mDef.NpuSupport) {
        New-Item -ItemType Directory -Path $geniexDir -Force | Out-Null
        try {
            New-Item -ItemType HardLink -Path $geniexFile -Target $localFile -ErrorAction Stop | Out-Null
            Write-Host "  [LINK] Hardlink creato: GenieX cache <-> models\$($mDef.TargetDir | Split-Path -Leaf)\$($mDef.File)" -ForegroundColor DarkCyan
        } catch {
            Write-Host "  [WARN] Impossibile creare hardlink GenieX per $($mDef.Name): $_" -ForegroundColor Yellow
        }
    }

    # 3. Registra geniex.json (UTF-8 No-BOM) se il file e presente in GenieX cache ed e supportato da NPU
    if ((Test-Path $geniexFile) -and $mDef.NpuSupport) {
        $jsonPath = Join-Path $geniexDir "geniex.json"
        if (-not (Test-Path $jsonPath)) {
            $fileSize = (Get-Item $geniexFile).Length
            $prec = if ($mDef.File -match "Q4_0") { "Q4_0" } elseif ($mDef.File -match "Q4_K_M") { "Q4_K_M" } else { "Q4_0" }
            $jsonObj = @{
                Name = $mDef.Repo
                ModelName = ($mDef.TargetDir | Split-Path -Leaf)
                ModelType = "llm"
                PluginId = "llama_cpp"
                ModelFile = @{
                    $prec = @{
                        Name = $mDef.File
                        Downloaded = $true
                        Size = $fileSize
                    }
                }
                MMProjFile = @{ Name = ""; Downloaded = $false; Size = 0 }
                TokenizerFile = @{ Name = ""; Downloaded = $false; Size = 0 }
                ExtraFiles = @()
            }
            $jsonContent = $jsonObj | ConvertTo-Json -Compress
            $utf8NoBom = [System.Text.UTF8Encoding]::new($false)
            [System.IO.File]::WriteAllText($jsonPath, $jsonContent, $utf8NoBom)
            Write-Host "  [GENIEX] Registrato $($mDef.Repo) per Hexagon NPU" -ForegroundColor DarkCyan
        }
    }
}

function Check-ModelExists {
    param ($mDef)
    $allFiles = @($mDef.File)
    if ($mDef.AltFiles) { $allFiles += $mDef.AltFiles }

    foreach ($f in $allFiles) {
        $paths = @(
            (Join-Path $mDef.TargetDir $f),
            (Join-Path $env:USERPROFILE ".cache\geniex\models\$($mDef.Repo)\$f"),
            (Join-Path $env:USERPROFILE "models\$($mDef.TargetDir | Split-Path -Leaf)\$f")
        )
        foreach ($p in $paths) {
            if (Test-Path $p) {
                Sync-ModelHardlink $mDef
                return $p
            }
        }
    }

    # Controllo se la cartella target contiene qualsiasi file GGUF
    if (Test-Path $mDef.TargetDir) {
        $anyGguf = Get-ChildItem -Path $mDef.TargetDir -Filter "*.gguf" -File | Select-Object -First 1
        if ($anyGguf) {
            Sync-ModelHardlink $mDef
            return $anyGguf.FullName
        }
    }
    return $null
}

function Download-SingleModel {
    param ($mDef)
    Write-Host "`n==========================================================" -ForegroundColor Cyan
    Write-Host " Inizio download: $($mDef.Name)" -ForegroundColor Yellow
    Write-Host " Repository : $($mDef.Repo)" -ForegroundColor DarkGray
    Write-Host " File       : $($mDef.File)" -ForegroundColor DarkGray
    Write-Host " Destinazione: $($mDef.TargetDir)" -ForegroundColor DarkGray
    Write-Host "==========================================================" -ForegroundColor Cyan

    New-Item -ItemType Directory -Path $mDef.TargetDir -Force | Out-Null

    $hfCmd = Get-Command "hf.exe" -ErrorAction SilentlyContinue
    $geniexCmd = Get-Command "geniex.exe" -ErrorAction SilentlyContinue
    if (-not $geniexCmd -and (Test-Path "$env:LOCALAPPDATA\GenieX CLI\geniex.exe")) {
        $geniexCmd = "$env:LOCALAPPDATA\GenieX CLI\geniex.exe"
    }

    $downloadSuccess = $false

    # 1. Tentativo con Hugging Face CLI
    if ($hfCmd) {
        Write-Host "[INFO] Download via Hugging Face CLI ('hf')..." -ForegroundColor Cyan
        & hf download $mDef.Repo $mDef.File --local-dir $mDef.TargetDir
        if ($LASTEXITCODE -eq 0) {
            $downloadSuccess = $true
            # Scarica eventuali file extra (es. Vision mmproj / draft)
            if ($mDef.ExtraFiles) {
                foreach ($ef in $mDef.ExtraFiles) {
                    Write-Host "[INFO] Download file supplementare: $ef..." -ForegroundColor DarkCyan
                    & hf download $mDef.Repo $ef --local-dir $mDef.TargetDir
                }
            }
        }
    }

    # 2. Tentativo con GenieX CLI se hf non presente o fallito
    if (-not $downloadSuccess -and $geniexCmd) {
        Write-Host "[INFO] Download / pull tramite GenieX CLI (NPU Hub)..." -ForegroundColor Cyan
        & $geniexCmd pull $mDef.Repo
        if ($LASTEXITCODE -eq 0) {
            $downloadSuccess = $true
        }
    }

    if ($downloadSuccess) {
        Write-Host "[OK] Download completato con successo!" -ForegroundColor Green
        # Sincronizza automaticamente gli HardLink tra models/ e .cache/geniex/models/
        Sync-ModelHardlink $mDef
        return $true
    }

    Write-Host "[ERR] Impossibile completare il download. Assicurati di avere 'hf' (pip install huggingface_hub[cli]) o GenieX CLI installato." -ForegroundColor Red
    return $false
}

Write-Host "=========================================================================" -ForegroundColor Cyan
Write-Host " ⚡ Snapdragon AI Stack: Downloader & Sync Modelli GGUF" -ForegroundColor Cyan
Write-Host "=========================================================================" -ForegroundColor Cyan

# Modalità Sincronizzazione HardLink
if ($SyncLinks) {
    Write-Host "`nSincronizzazione HardLink NTFS (GPU <-> NPU) in corso..." -ForegroundColor Cyan
    foreach ($m in $ModelDefinitions) {
        $exists = Check-ModelExists $m
    }
    Write-Host "[OK] Sincronizzazione completata a zero consumo di spazio disco!" -ForegroundColor Green
    exit 0
}

# Modalità non interattiva per parametri diretti
if ($ModelName) {
    $matched = $ModelDefinitions | Where-Object { $_.Id -eq $ModelName.ToLower() -or $_.Name -like "*$ModelName*" }
    if ($matched) {
        Download-SingleModel $matched[0]
    } else {
        Write-Host "[ERR] Modello '$ModelName' non riconosciuto." -ForegroundColor Red
    }
    exit 0
}

if ($All) {
    foreach ($m in $ModelDefinitions) {
        Download-SingleModel $m
    }
    exit 0
}

if ($MissingOnly) {
    foreach ($m in $ModelDefinitions) {
        $exists = Check-ModelExists $m
        if (-not $exists) {
            Download-SingleModel $m
        } else {
            Write-Host "[INFO] $($m.Name) già presente in: $exists" -ForegroundColor DarkGreen
        }
    }
    exit 0
}

# Menu interattivo
Write-Host "`nStato dei modelli nel sistema (NPU Hexagon & GPU Vulkan):" -ForegroundColor DarkCyan
foreach ($m in $ModelDefinitions) {
    $exists = Check-ModelExists $m
    $statusText = if ($exists) { "[PRESENTE]" } else { "[MANCANTE]" }
    $color = if ($exists) { "Green" } else { "Yellow" }
    Write-Host "  $($m.Key). $($m.Name.PadRight(42)) " -NoNewline
    Write-Host $statusText -ForegroundColor $color
}

Write-Host "`nOpzioni disponibili:" -ForegroundColor DarkCyan
Write-Host "  1-7. Scarica un singolo modello specifico"
Write-Host "  M.   Scarica tutti i modelli [MANCANTI]"
Write-Host "  S.   Sincronizza HardLinks (Collega GPU e NPU senza duplicare spazio)"
Write-Host "  A.   Scarica TUTTI i modelli"
Write-Host "  0.   Esci"
Write-Host ""

if ($NonInteractive) {
    exit 0
}

$choice = Read-Host "Seleziona un'opzione (es. 1-7 per scaricare, S per sincronizzare link, M per i mancanti)"

switch -Regex ($choice.Trim()) {
    "^[1-7]$" {
        $target = $ModelDefinitions | Where-Object { $_.Key -eq $choice.Trim() }
        if ($target) { Download-SingleModel $target }
    }
    "^[sS]$" {
        foreach ($m in $ModelDefinitions) {
            Check-ModelExists $m | Out-Null
        }
        Write-Host "[OK] Tutti i modelli sono ora sincronizzati tra GPU e NPU!" -ForegroundColor Green
    }
    "^[mM]$" {
        foreach ($m in $ModelDefinitions) {
            $exists = Check-ModelExists $m
            if (-not $exists) {
                Download-SingleModel $m
            }
        }
    }
    "^[aA]$" {
        foreach ($m in $ModelDefinitions) {
            Download-SingleModel $m
        }
    }
    default {
        Write-Host "Operazione annullata o uscita." -ForegroundColor DarkGray
    }
}