param (
    [string]$LlamaCppDir,
    [string]$BuildDir
)

# build_vulkan_arm64.ps1
# Compila llama.cpp con backend Vulkan bare-metal per Adreno X2-90 su Windows ARM64

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path $PSScriptRoot -Parent

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " ⚡ Build Nativa ARM64 Vulkan (llama.cpp)" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Ricerca dinamica dei percorsi della toolchain
$ToolchainCandidates = @(
    (Join-Path $RepoRoot "toolchain"),
    (Join-Path $env:USERPROFILE "toolchain")
)

$AddedPaths = [System.Collections.Generic.List[string]]::new()

foreach ($tc in $ToolchainCandidates) {
    if (Test-Path $tc) {
        # LLVM-MinGW bin
        $llvmBin = Get-ChildItem -Path $tc -Filter "llvm-mingw*" -Directory -ErrorAction SilentlyContinue | ForEach-Object { Join-Path $_.FullName "bin" } | Where-Object { Test-Path $_ } | Select-Object -First 1
        if ($llvmBin -and -not $AddedPaths.Contains($llvmBin)) { $AddedPaths.Add($llvmBin) }

        # Ninja
        $ninjaBin = Join-Path $tc "ninja"
        if ((Test-Path $ninjaBin) -and -not $AddedPaths.Contains($ninjaBin)) { $AddedPaths.Add($ninjaBin) }

        # CMake bin
        $cmakeBin = Get-ChildItem -Path $tc -Filter "cmake*" -Directory -ErrorAction SilentlyContinue | ForEach-Object { Join-Path $_.FullName "bin" } | Where-Object { Test-Path $_ } | Select-Object -First 1
        if ($cmakeBin -and -not $AddedPaths.Contains($cmakeBin)) { $AddedPaths.Add($cmakeBin) }

        # Vulkan SDK bin
        $vkSdkBin = Join-Path $tc "vulkan_sdk\Bin"
        if ((Test-Path $vkSdkBin) -and -not $AddedPaths.Contains($vkSdkBin)) { $AddedPaths.Add($vkSdkBin) }
    }
}

# Add user profile vulkan_sdk if present
$userVkSdk = Join-Path $env:USERPROFILE "vulkan_sdk\Bin"
if ((Test-Path $userVkSdk) -and -not $AddedPaths.Contains($userVkSdk)) { $AddedPaths.Add($userVkSdk) }

if ($AddedPaths.Count -gt 0) {
    $env:PATH = ($AddedPaths -join ";") + ";$env:PATH"
    Write-Host "[INFO] Toolchain integrata nel PATH:" -ForegroundColor Gray
    $AddedPaths | ForEach-Object { Write-Host "  -> $_" -ForegroundColor DarkGray }
}

# 2. Verifica driver Vulkan host
if (-not (Test-Path "C:\Windows\System32\vulkan-1.dll")) {
    Write-Error "Driver Vulkan host non trovato in C:\Windows\System32\vulkan-1.dll"
}

# 3. Individuazione directory sorgente e build di llama.cpp
if (-not $LlamaCppDir) {
    $LlamaCandidates = @(
        (Join-Path $RepoRoot "..\llama.cpp"),
        (Join-Path $RepoRoot "llama.cpp"),
        (Join-Path $env:USERPROFILE "llama.cpp")
    )
    foreach ($cand in $LlamaCandidates) {
        if (Test-Path $cand) {
            $LlamaCppDir = (Resolve-Path $cand).Path
            break
        }
    }
}

if (-not $BuildDir) {
    if ($LlamaCppDir) {
        $buildVulkan = Join-Path $LlamaCppDir "build-vulkan"
        $buildDefault = Join-Path $LlamaCppDir "build"
        if (Test-Path $buildVulkan) {
            $BuildDir = $buildVulkan
        } elseif (Test-Path $buildDefault) {
            $BuildDir = $buildDefault
        } else {
            $BuildDir = $buildVulkan
        }
    }
}

# 4. Invocazione Ninja
if ($BuildDir -and (Test-Path $BuildDir)) {
    Write-Host "Compilazione binari in corso via Ninja in: $BuildDir" -ForegroundColor Yellow
    & "ninja" -C $BuildDir llama-server llama-bench llama-cli
    
    # Copia artefatti in bin/
    $BinDir = Join-Path $RepoRoot "bin\llama-cpp-vulkan-arm64"
    New-Item -ItemType Directory -Path $BinDir -Force | Out-Null
    Copy-Item -Path "$BuildDir\bin\llama-server.exe" -Destination "$BinDir\" -Force
    Copy-Item -Path "$BuildDir\bin\llama-bench.exe" -Destination "$BinDir\" -Force
    Copy-Item -Path "$BuildDir\bin\llama-cli.exe" -Destination "$BinDir\" -Force
    
    Write-Host "Binari aggiornati con successo in $BinDir" -ForegroundColor Green
} else {
    $targetRef = if ($LlamaCppDir) { $LlamaCppDir } else { "della cartella llama.cpp" }
    Write-Host "Cartella di build non trovata ($BuildDir)." -ForegroundColor Yellow
    Write-Host "Esegui prima la configurazione CMake all'interno di: $targetRef" -ForegroundColor Yellow
}