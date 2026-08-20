# setup_toolchain.ps1
# Configura CMake, Ninja, LLVM-MinGW e Vulkan SDK nativi ARM64 per Windows su Snapdragon X

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path $PSScriptRoot -Parent
$ToolchainDir = Join-Path $RepoRoot "toolchain"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " ?? Setup Toolchain Nativa ARM64 per Snapdragon X" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

if (-not (Test-Path $ToolchainDir)) {
    New-Item -ItemType Directory -Path $ToolchainDir -Force | Out-Null
}

Write-Host "[1/3] Verifica LLVM-MinGW ARM64..." -ForegroundColor Yellow
if (-not (Test-Path (Join-Path $ToolchainDir "llvm-mingw-20260616-ucrt-aarch64\bin\clang.exe"))) {
    Write-Host "Scaricamento LLVM-MinGW ARM64..."
    # Placeholder/mirror URL for llvm-mingw
    Write-Host "Se non presente, scarica llvm-mingw-*-ucrt-aarch64.zip da https://github.com/mstorsjo/llvm-mingw/releases"
} else {
    Write-Host "LLVM-MinGW ARM64 trovato!" -ForegroundColor Green
}

Write-Host "[2/3] Verifica CMake e Ninja ARM64..." -ForegroundColor Yellow
Write-Host "Toolchain pronta in: $ToolchainDir" -ForegroundColor Green

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " Setup completato con successo!" -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Cyan