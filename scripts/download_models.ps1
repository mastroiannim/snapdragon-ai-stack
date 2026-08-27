# download_models.ps1
# Script per scaricare e predisporre i modelli GGUF ottimizzati per Snapdragon X tramite CLI 'hf'

param (
    [string]$ModelName = "",
    [switch]$All,
    [switch]$MissingOnly,
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
        Description = "Chat rapida, scrittura fluida (~35 tok/s) o Hexagon NPU"
    },
    @{
        Key = "2"
        Id = "qwen27b"
        Name = "Qwen3.8-27B AWQ (15.2 GB)"
        Repo = "IvanKrastevAdventics/Qwen3.8-27B-AWQ-INT4-Q4_0-GGUF"
        File = "qwen3.8-27b-awq-int4-q4_0.gguf"
        TargetDir = Join-Path $ModelsDir "Qwen3.8-27B"
        Description = "Coding complesso in VSCode Cline (~12 tok/s)"
    },
    @{
        Key = "3"
        Id = "muse30b"
        Name = "Muse-Glimmer-30B Vision (16.1 GB)"
        Repo = "unsloth/Muse-Glimmer-30B-GGUF"
        File = "Muse-Glimmer-30B-Q4_K_M.gguf"
        TargetDir = Join-Path $ModelsDir "Muse-Glimmer-30B"
        Description = "Visione multimodale + Speculative DFlash (~20 tok/s)"
    },
    @{
        Key = "4"
        Id = "gemma31b"
        Name = "Gemma-4-31B-it QAT (18.5 GB)"
        Repo = "google/gemma-4-31B-it-qat-q4_0-gguf"
        File = "gemma-4-31B_q4_0-it.gguf"
        TargetDir = Join-Path $ModelsDir "Gemma-4-31B"
        Description = "Ragionamento avanzato e coding multi-step (~6-9 tok/s)"
    },
    @{
        Key = "5"
        Id = "phi4mini"
        Name = "Phi-4-Mini-Instruct (2.49 GB - Qualcomm AI Hub)"
        Repo = "unsloth/Phi-4-mini-instruct-GGUF"
        File = "Phi-4-mini-instruct-Q4_K_M.gguf"
        TargetDir = Join-Path $ModelsDir "Phi-4-mini-instruct"
        Description = "Logica matematica, reasoning veloce (~45-65 tok/s GPU / >1200 NPU)"
    }
)

function Check-ModelExists {
    param ($mDef)
    $paths = @(
        (Join-Path $mDef.TargetDir $mDef.File),
        (Join-Path $env:USERPROFILE "models\$($mDef.TargetDir | Split-Path -Leaf)\$($mDef.File)"),
        (Join-Path $env:USERPROFILE ".cache\geniex\models\$($mDef.Repo)\$($mDef.File)")
    )
    foreach ($p in $paths) {
        if (Test-Path $p) { return $p }
    }
    # Check if target directory has any GGUF file
    if (Test-Path $mDef.TargetDir) {
        $anyGguf = Get-ChildItem -Path $mDef.TargetDir -Filter "*.gguf" -File | Select-Object -First 1
        if ($anyGguf) { return $anyGguf.FullName }
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
    if ($hfCmd) {
        & hf download $mDef.Repo $mDef.File --local-dir $mDef.TargetDir
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[OK] Download completato con successo in $($mDef.TargetDir)!" -ForegroundColor Green
            return $true
        } else {
            Write-Host "[ERR] Download tramite 'hf' non riuscito (Codice $LASTEXITCODE)." -ForegroundColor Red
            return $false
        }
    } else {
        Write-Host "[ERR] Tool 'hf' non trovato nel PATH. Installa con 'pip install huggingface_hub[cli]'." -ForegroundColor Red
        return $false
    }
}

Write-Host "=========================================================================" -ForegroundColor Cyan
Write-Host " ⚡ Snapdragon AI Stack: Downloader Modelli GGUF" -ForegroundColor Cyan
Write-Host "=========================================================================" -ForegroundColor Cyan

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
Write-Host "`nStato dei modelli nel sistema:" -ForegroundColor DarkCyan
foreach ($m in $ModelDefinitions) {
    $exists = Check-ModelExists $m
    $statusText = if ($exists) { "[PRESENTE]" } else { "[MANCANTE]" }
    $color = if ($exists) { "Green" } else { "Yellow" }
    Write-Host "  $($m.Key). $($m.Name.PadRight(42)) " -NoNewline
    Write-Host $statusText -ForegroundColor $color
}

Write-Host "`nOpzioni di download:" -ForegroundColor DarkCyan
Write-Host "  1-5. Scarica un singolo modello specifico"
Write-Host "  M.   Scarica tutti i modelli [MANCANTI]"
Write-Host "  A.   Scarica TUTTI i modelli"
Write-Host "  0.   Esci"
Write-Host ""

if ($NonInteractive) {
    exit 0
}

$choice = Read-Host "Seleziona un'opzione (es. 5 per Phi-4-Mini, M per i mancanti)"

switch -Regex ($choice.Trim()) {
    "^[1-5]$" {
        $target = $ModelDefinitions | Where-Object { $_.Key -eq $choice.Trim() }
        if ($target) { Download-SingleModel $target }
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