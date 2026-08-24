<#
.SYNOPSIS
    Script di Onboarding, Diagnostica e Configurazione Automatica per Snapdragon AI Stack.
.DESCRIPTION
    Scansiona l'ambiente di esecuzione (Windows 11 on ARM64), rileva e configura le risorse
    necessarie (WSL2 mirrored networking, Node.js, GenieX NPU, binari Vulkan/Hexagon, modelli GGUF, toolchain).
.PARAMETER AutoFix
    Applica automaticamente le correzioni raccomandate (es. configurazione .wslconfig, generazione lib Vulkan).
.PARAMETER DownloadModels
    Avvia automaticamente lo script per il download dei modelli se mancanti.
.PARAMETER SetupToolchain
    Avvia automaticamente lo script di installazione della toolchain se mancante.
#>

param (
    [switch]$AutoFix,
    [switch]$DownloadModels,
    [switch]$SetupToolchain,
    [switch]$NonInteractive
)

$ErrorActionPreference = "Continue"
$RepoRoot = Split-Path $PSScriptRoot -Parent
$IsInteractive = -not $NonInteractive -and ([Environment]::UserInteractive)

function Write-Header {
    param ([string]$Text)
    Write-Host ""
    Write-Host "=========================================================================" -ForegroundColor Cyan
    Write-Host " $Text" -ForegroundColor Cyan
    Write-Host "=========================================================================" -ForegroundColor Cyan
}

function Write-StatusItem {
    param (
        [string]$Status, # OK, WARN, ERR, INFO
        [string]$Label,
        [string]$Detail = ""
    )
    $badge = switch ($Status) {
        "OK"   { "[OK]   " }
        "WARN" { "[WARN] " }
        "ERR"  { "[ERR]  " }
        "INFO" { "[INFO] " }
        default{ "[    ] " }
    }
    $color = switch ($Status) {
        "OK"   { "Green" }
        "WARN" { "Yellow" }
        "ERR"  { "Red" }
        "INFO" { "Cyan" }
        default{ "White" }
    }
    Write-Host $badge -ForegroundColor $color -NoNewline
    Write-Host "$Label " -ForegroundColor White -NoNewline
    if ($Detail) {
        Write-Host "- $Detail" -ForegroundColor DarkGray
    } else {
        Write-Host ""
    }
}

Write-Header "Snapdragon AI Stack: Onboarding & Diagnostica Risorse"
Write-Host "Posizione Repository: $RepoRoot" -ForegroundColor DarkCyan
Write-Host "Data e Ora Scansione: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor DarkCyan

$AllOk = $true
$FixesApplied = @()

# -----------------------------------------------------------------------------
# 1. ARCHITETTURA E HARDWARE
# -----------------------------------------------------------------------------
Write-Header "1. Verifica Hardware & Driver Host"

$arch = $env:PROCESSOR_ARCHITECTURE
$nativeArch = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture
$isArm64 = ($arch -eq "ARM64" -or "$nativeArch" -eq "Arm64")

if ($isArm64) {
    Write-StatusItem "OK" "Architettura CPU" "Nativa ARM64 / Snapdragon X ($arch)"
} else {
    Write-StatusItem "WARN" "Architettura CPU" "Rilevato $arch (l'hardware ottimale e Snapdragon X ARM64)"
}

# RAM di sistema
try {
    $ram = Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum
    $ramGb = [Math]::Round($ram.Sum / 1GB, 1)
    Write-StatusItem "OK" "Memoria RAM Totale" "$ramGb GB (Architettura UMA CPU/GPU/NPU)"
} catch {
    Write-StatusItem "INFO" "Memoria RAM" "Non determinabile via WMI"
}

# Driver Vulkan Adreno
$vulkanDll = "C:\Windows\System32\vulkan-1.dll"
if (Test-Path $vulkanDll) {
    Write-StatusItem "OK" "Driver Vulkan Adreno Host" "$vulkanDll presente"
} else {
    Write-StatusItem "ERR" "Driver Vulkan Adreno Host" "$vulkanDll non trovato in System32"
    $AllOk = $false
}

# -----------------------------------------------------------------------------
# 2. NETWORKING WSL2 (.wslconfig) & OPEN-WEBUI
# -----------------------------------------------------------------------------
Write-Header "2. Ambiente WSL2 & Open-WebUI"

$wslConfigPath = Join-Path $env:USERPROFILE ".wslconfig"
$wslConfigTemplate = Join-Path $RepoRoot "configs\wslconfig.template"
$wslConfigConfigured = $false

if (Test-Path $wslConfigPath) {
    $content = Get-Content $wslConfigPath -Raw
    if ($content -match "networkingMode\s*=\s*mirrored") {
        Write-StatusItem "OK" "WSL2 Networking Mode" "Mirrored configurato in $wslConfigPath"
        $wslConfigConfigured = $true
    } else {
        Write-StatusItem "WARN" "WSL2 Networking Mode" "Presente ma senza 'networkingMode=mirrored'"
    }
} else {
    Write-StatusItem "WARN" "WSL2 .wslconfig" "File non presente in $env:USERPROFILE"
}

if (-not $wslConfigConfigured) {
    $shouldApply = $AutoFix
    if (-not $shouldApply -and $IsInteractive) {
        $ans = Read-Host "Vuoi configurare automaticamente .wslconfig (Mirrored Mode) da template? (S/N)"
        if ($ans -match "^[sSyY]") { $shouldApply = $true }
    }
    if ($shouldApply -and (Test-Path $wslConfigTemplate)) {
        try {
            Copy-Item -Path $wslConfigTemplate -Destination $wslConfigPath -Force
            Write-StatusItem "OK" "Auto-Fix .wslconfig" "Copiato con successo in $wslConfigPath"
            $FixesApplied += ".wslconfig configurato in Mirrored Mode (Esegui 'wsl --shutdown' per applicare)"
            $wslConfigConfigured = $true
        } catch {
            Write-StatusItem "ERR" "Auto-Fix .wslconfig" "Errore durante la copia: $_"
        }
    }
}

# Verifica WSL2 eseguibile e distro
$wslCmd = Get-Command "wsl.exe" -ErrorAction SilentlyContinue
if ($wslCmd) {
    Write-StatusItem "OK" "Eseguibile WSL2" "wsl.exe disponibile"
    # Controlla distro Ubuntu
    $wslDistros = wsl --list --quiet 2>$null
    if ($wslDistros -match "Ubuntu") {
        Write-StatusItem "OK" "Distro WSL Ubuntu" "Rilevata"
    } else {
        Write-StatusItem "INFO" "Distro WSL Ubuntu" "Non rilevata tra le distro predefinite"
    }
} else {
    Write-StatusItem "WARN" "WSL2" "wsl.exe non trovato. Installa con 'wsl --install -d Ubuntu' per Open-WebUI."
}

# -----------------------------------------------------------------------------
# 3. RUNTIME COMPONENTI (Node.js & GenieX NPU)
# -----------------------------------------------------------------------------
Write-Header "3. Runtime & Servizi Middleware"

# Node.js
$nodeCmd = Get-Command "node.exe" -ErrorAction SilentlyContinue
if ($nodeCmd) {
    $nodeVer = & node -v 2>$null
    Write-StatusItem "OK" "Node.js (Caveman Proxy)" "$($nodeCmd.Source) ($nodeVer)"
} else {
    Write-StatusItem "WARN" "Node.js (Caveman Proxy)" "node.exe non trovato nel PATH (Necessario per porta 18182)"
}

# GenieX CLI (NPU)
$geniexCandidates = @(
    (Join-Path $env:LOCALAPPDATA "GenieX CLI\geniex.exe"),
    (Join-Path $env:USERPROFILE "AppData\Local\GenieX CLI\geniex.exe")
)
$geniexFound = $null
foreach ($cand in $geniexCandidates) {
    if (Test-Path $cand) {
        $geniexFound = $cand
        break
    }
}
if (-not $geniexFound) {
    $gCmd = Get-Command "geniex.exe" -ErrorAction SilentlyContinue
    if ($gCmd) { $geniexFound = $gCmd.Source }
}

if ($geniexFound) {
    Write-StatusItem "OK" "GenieX CLI (Hexagon NPU)" "$geniexFound"
} else {
    Write-StatusItem "INFO" "GenieX CLI (Hexagon NPU)" "Non trovato. Scaricabile da geniex.ai per NPU 80 TOPS."
}

# -----------------------------------------------------------------------------
# 4. BINARI DI INFERENZA & LIBRERIE SDK
# -----------------------------------------------------------------------------
Write-Header "4. Motori di Inferenza Nativa (bin/ e sdk/)"

$vulkanServer = Join-Path $RepoRoot "bin\llama-cpp-vulkan-arm64\llama-server.exe"
if (Test-Path $vulkanServer) {
    Write-StatusItem "OK" "llama-cpp-vulkan-arm64" "llama-server.exe pronto (Adreno GPU)"
} else {
    Write-StatusItem "WARN" "llama-cpp-vulkan-arm64" "Binario non trovato in bin/llama-cpp-vulkan-arm64/"
}

$hexagonDir = Join-Path $RepoRoot "bin\llama-cpp-hexagon-arm64"
if (Test-Path $hexagonDir) {
    Write-StatusItem "OK" "llama-cpp-hexagon-arm64" "Runtime Hexagon NPU QAIRT presente"
} else {
    Write-StatusItem "INFO" "llama-cpp-hexagon-arm64" "Cartella opzionale non presente"
}

# Verifica / Generazione librerie Vulkan SDK
$vulkanA = Join-Path $RepoRoot "sdk\vulkan_lib\libvulkan-1.a"
$vulkanLib = Join-Path $RepoRoot "sdk\vulkan_lib\vulkan-1.lib"
if ((Test-Path $vulkanA) -and (Test-Path $vulkanLib)) {
    Write-StatusItem "OK" "Librerie Vulkan ARM64 SDK" "libvulkan-1.a e vulkan-1.lib pronte"
} else {
    Write-StatusItem "WARN" "Librerie Vulkan ARM64 SDK" "Librerie di importazione non generate"
    $genScript = Join-Path $RepoRoot "scripts\generate_vulkan_lib.ps1"
    if (Test-Path $genScript) {
        Write-Host "Generazione automatica librerie Vulkan ARM64 in corso..." -ForegroundColor Yellow
        & $genScript
        if ((Test-Path $vulkanA) -and (Test-Path $vulkanLib)) {
            Write-StatusItem "OK" "Librerie Vulkan ARM64 SDK" "Generate con successo!"
            $FixesApplied += "Librerie Vulkan ARM64 generate in sdk/vulkan_lib/"
        }
    }
}

# -----------------------------------------------------------------------------
# 5. MODELLI GGUF
# -----------------------------------------------------------------------------
Write-Header "5. Modelli GGUF per Inferenza Locale"

$ModelsBaseDirs = @(
    (Join-Path $RepoRoot "models"),
    (Join-Path $env:USERPROFILE "models"),
    (Join-Path $env:USERPROFILE ".cache\geniex\models")
)

$ModelChecks = @(
    @{
        Name = "Qwen3-8B (GPU/NPU)"
        Patterns = @("Qwen3-8B*.gguf", "*8B*.gguf", "Qwen3-8B-128K-Q4_0.gguf")
        SubDir = "Qwen3-8B"
        DownloadHint = "unsloth/Qwen3-8B-128K-GGUF"
    },
    @{
        Name = "Qwen3.8-27B (GPU Coding)"
        Patterns = @("qwen3.8-27b*.gguf", "*27b*.gguf", "qwen3.8-27b-awq-int4-q4_0.gguf")
        SubDir = "Qwen3.8-27B"
        DownloadHint = "IvanKrastevAdventics/Qwen3.8-27B-AWQ-INT4-Q4_0-GGUF"
    },
    @{
        Name = "Muse-Glimmer-30B (Vision Multimodal)"
        Patterns = @("Muse-Glimmer-30B-Q4_K_M.gguf", "*Muse-Glimmer*.gguf")
        SubDir = "Muse-Glimmer-30B"
        DownloadHint = "Muse-Glimmer-30B-Q4_K_M.gguf"
    }
)

$MissingModels = @()

foreach ($mc in $ModelChecks) {
    $found = $null
    foreach ($bDir in $ModelsBaseDirs) {
        if (Test-Path $bDir) {
            $subPath = Join-Path $bDir $mc.SubDir
            if (Test-Path $subPath) {
                foreach ($pat in $mc.Patterns) {
                    $match = Get-ChildItem -Path $subPath -Filter $pat -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 1
                    if ($match) {
                        $found = $match.FullName
                        break
                    }
                }
            }
            if (-not $found) {
                foreach ($pat in $mc.Patterns) {
                    $match = Get-ChildItem -Path $bDir -Filter $pat -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 1
                    if ($match) {
                        $found = $match.FullName
                        break
                    }
                }
            }
        }
        if ($found) { break }
    }

    if ($found) {
        $sizeGb = [Math]::Round((Get-Item $found).Length / 1GB, 2)
        Write-StatusItem "OK" $mc.Name "$found ($sizeGb GB)"
    } else {
        Write-StatusItem "WARN" $mc.Name "Non trovato nei percorsi di default (Hint: $($mc.DownloadHint))"
        $MissingModels += $mc
    }
}

if ($MissingModels.Count -gt 0) {
    $shouldDownload = $DownloadModels
    if (-not $shouldDownload -and $IsInteractive) {
        $ans = Read-Host "Alcuni modelli non sono stati trovati. Vuoi avviare scripts\download_models.ps1? (S/N)"
        if ($ans -match "^[sSyY]") { $shouldDownload = $true }
    }
    if ($shouldDownload) {
        $dlScript = Join-Path $RepoRoot "scripts\download_models.ps1"
        if (Test-Path $dlScript) {
            & $dlScript
        }
    }
}

# -----------------------------------------------------------------------------
# 6. TOOLCHAIN DI COMPILAZIONE (Opzionale per Sviluppatori)
# -----------------------------------------------------------------------------
Write-Header "6. Toolchain di Sviluppo & Compilazione ARM64 (Opzionale)"

$tcDirs = @(
    (Join-Path $RepoRoot "toolchain"),
    (Join-Path $env:USERPROFILE "toolchain")
)
$hasLlvm = $false
$hasCmake = $false
$hasNinja = $false

foreach ($tcd in $tcDirs) {
    if (Test-Path $tcd) {
        if (Get-ChildItem -Path $tcd -Filter "llvm-mingw*" -Directory -ErrorAction SilentlyContinue) { $hasLlvm = $true }
        if (Get-ChildItem -Path $tcd -Filter "cmake*" -Directory -ErrorAction SilentlyContinue) { $hasCmake = $true }
        if (Test-Path (Join-Path $tcd "ninja\ninja.exe")) { $hasNinja = $true }
    }
}

if ($hasLlvm -and $hasCmake -and $hasNinja) {
    Write-StatusItem "OK" "Toolchain Nativa ARM64" "LLVM-MinGW, CMake e Ninja configurati"
} else {
    Write-StatusItem "INFO" "Toolchain Nativa ARM64" "Parziale o non presente (Necessaria solo per compilare da sorgenti)"
    if ($SetupToolchain) {
        $setupTc = Join-Path $RepoRoot "scripts\setup_toolchain.ps1"
        if (Test-Path $setupTc) { & $setupTc }
    }
}

# -----------------------------------------------------------------------------
# RIEPILOGO FINALE & PROSSIMI PASSI
# -----------------------------------------------------------------------------
Write-Header "Riepilogo & Guida Rapida Avvio"

if ($FixesApplied.Count -gt 0) {
    Write-Host "Modifiche applicate automaticamente durante l'onboarding:" -ForegroundColor Yellow
    foreach ($fix in $FixesApplied) {
        Write-Host "  * $fix" -ForegroundColor Green
    }
    Write-Host ""
}

Write-Host "Launcher disponibili in launchers/:" -ForegroundColor Cyan
Write-Host "  0. 0_Setup_Onboarding.cmd           -> Riesegui verifica & configurazione stack" -ForegroundColor White
Write-Host "  1. 2_Server_GenieX_NPU.cmd          -> Server NPU Hexagon 80 TOPS (Porta 18181)" -ForegroundColor White
Write-Host "  2. 4_Server_Qwen8B_GPU.cmd          -> Server GPU Adreno Vulkan Qwen3-8B (Porta 18185)" -ForegroundColor White
Write-Host "  3. 5_Server_Qwen27B_GPU.cmd         -> Server GPU Adreno Vulkan Qwen3.8-27B (Porta 18184)" -ForegroundColor White
Write-Host "  4. 6_Proxy_Compressore_OpenClaw.cmd -> Caveman Fast Proxy con compressione prompt (Porta 18182)" -ForegroundColor White
Write-Host "  5. 1_Avvia_Dashboard_WebUI.cmd      -> Dashboard Chat Open-WebUI (Porta 8080)" -ForegroundColor White
Write-Host "  6. Stop_Tutti_I_Server.cmd          -> Termina tutti i processi e libera memoria" -ForegroundColor White
Write-Host ""
Write-Host "=========================================================================" -ForegroundColor Cyan
Write-Host " Verifica completata! Per iniziare, esegui un server o il proxy." -ForegroundColor Green
Write-Host "=========================================================================" -ForegroundColor Cyan
