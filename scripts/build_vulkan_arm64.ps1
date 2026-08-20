# build_vulkan_arm64.ps1
# Compila llama.cpp con backend Vulkan bare-metal per Adreno X2-90 su Windows ARM64

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path $PSScriptRoot -Parent

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " ??? Build Nativa ARM64 Vulkan (llama.cpp)" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Path toolchain
$env:PATH = "C:\Users\mstmh\toolchain\llvm-mingw-20260616-ucrt-aarch64\bin;C:\Users\mstmh\toolchain\ninja;C:\Users\mstmh\toolchain\cmake-3.31.5-windows-arm64\bin;C:\Users\mstmh\vulkan_sdk\Bin;$env:PATH"

# 2. Verifica driver Vulkan host
if (-not (Test-Path "C:\Windows\System32\vulkan-1.dll")) {
    Write-Error "Driver Vulkan host non trovato in C:\Windows\System32\vulkan-1.dll"
}

# 3. Invocazione Ninja
$BuildDir = "C:\Users\mstmh\llama.cpp\build-vulkan"
if (Test-Path $BuildDir) {
    Write-Host "Compilazione binari in corso via Ninja..." -ForegroundColor Yellow
    & "ninja" -C $BuildDir llama-server llama-bench llama-cli
    
    # Copia artefatti in bin/
    $BinDir = Join-Path $RepoRoot "bin\llama-cpp-vulkan-arm64"
    New-Item -ItemType Directory -Path $BinDir -Force | Out-Null
    Copy-Item -Path "$BuildDir\bin\llama-server.exe" -Destination "$BinDir\" -Force
    Copy-Item -Path "$BuildDir\bin\llama-bench.exe" -Destination "$BinDir\" -Force
    Copy-Item -Path "$BuildDir\bin\llama-cli.exe" -Destination "$BinDir\" -Force
    
    Write-Host "Binari aggiornati con successo in $BinDir" -ForegroundColor Green
} else {
    Write-Host "Esegui prima la configurazione CMake da C:\Users\mstmh\llama.cpp" -ForegroundColor Yellow
}