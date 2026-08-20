<#
.SYNOPSIS
    Setup automatico della toolchain di compilazione nativa ARM64 per Windows su Snapdragon X.
.DESCRIPTION
    Scarica e installa in locale:
    1. LLVM-MinGW (Clang/LLVM 22.x nativo AArch64)
    2. CMake (Windows ARM64)
    3. Ninja (Windows ARM64)
    4. Vulkan SDK & glslc (Shader Compiler)
#>

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path $PSScriptRoot -Parent
$ToolchainDir = Join-Path $RepoRoot "toolchain"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " ?? Setup Toolchain Nativa ARM64 per Snapdragon X" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

if (-not (Test-Path $ToolchainDir)) {
    New-Item -ItemType Directory -Path $ToolchainDir -Force | Out-Null
}

# 1. LLVM-MinGW ARM64
$llvmDir = Join-Path $ToolchainDir "llvm-mingw-20260616-ucrt-aarch64"
if (-not (Test-Path (Join-Path $llvmDir "bin\clang.exe"))) {
    Write-Host "[1/4] Scaricamento LLVM-MinGW ARM64..." -ForegroundColor Yellow
    $llvmZip = Join-Path $ToolchainDir "llvm-mingw.zip"
    $llvmUrl = "https://github.com/mstorsjo/llvm-mingw/releases/download/20260616/llvm-mingw-20260616-ucrt-aarch64.zip"
    if (-not (Test-Path $llvmZip)) {
        Invoke-WebRequest -Uri $llvmUrl -OutFile $llvmZip -UseBasicParsing
    }
    Expand-Archive -Path $llvmZip -DestinationPath $ToolchainDir -Force
    Write-Host "LLVM-MinGW estratto con successo!" -ForegroundColor Green
} else {
    Write-Host "[1/4] LLVM-MinGW ARM64 gia presente." -ForegroundColor Green
}

# 2. CMake ARM64
$cmakeDir = Join-Path $ToolchainDir "cmake-3.31.5-windows-arm64"
if (-not (Test-Path (Join-Path $cmakeDir "bin\cmake.exe"))) {
    Write-Host "[2/4] Scaricamento CMake ARM64..." -ForegroundColor Yellow
    $cmakeZip = Join-Path $ToolchainDir "cmake.zip"
    $cmakeUrl = "https://github.com/Kitware/CMake/releases/download/v3.31.5/cmake-3.31.5-windows-arm64.zip"
    if (-not (Test-Path $cmakeZip)) {
        Invoke-WebRequest -Uri $cmakeUrl -OutFile $cmakeZip -UseBasicParsing
    }
    Expand-Archive -Path $cmakeZip -DestinationPath $ToolchainDir -Force
    Write-Host "CMake ARM64 estratto con successo!" -ForegroundColor Green
} else {
    Write-Host "[2/4] CMake ARM64 gia presente." -ForegroundColor Green
}

# 3. Ninja ARM64
$ninjaDir = Join-Path $ToolchainDir "ninja"
if (-not (Test-Path (Join-Path $ninjaDir "ninja.exe"))) {
    Write-Host "[3/4] Scaricamento Ninja ARM64..." -ForegroundColor Yellow
    $ninjaZip = Join-Path $ToolchainDir "ninja.zip"
    $ninjaUrl = "https://github.com/ninja-build/ninja/releases/download/v1.12.1/ninja-winarm64.zip"
    if (-not (Test-Path $ninjaZip)) {
        Invoke-WebRequest -Uri $ninjaUrl -OutFile $ninjaZip -UseBasicParsing
    }
    New-Item -ItemType Directory -Path $ninjaDir -Force | Out-Null
    Expand-Archive -Path $ninjaZip -DestinationPath $ninjaDir -Force
    Write-Host "Ninja ARM64 estratto con successo!" -ForegroundColor Green
} else {
    Write-Host "[3/4] Ninja ARM64 gia presente." -ForegroundColor Green
}

# 4. Generazione librerie Vulkan
Write-Host "[4/4] Configurazione Librerie Vulkan per Adreno..." -ForegroundColor Yellow
& "$PSScriptRoot\generate_vulkan_lib.ps1"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " ?? Toolchain e SDK configurati con successo in: $ToolchainDir" -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Cyan