<#
.SYNOPSIS
    Genera libvulkan-1.a e vulkan-1.lib direttamente dal driver Vulkan host in C:\Windows\System32\vulkan-1.dll
#>

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path $PSScriptRoot -Parent
$SdkLibDir = Join-Path $RepoRoot "sdk\vulkan_lib"

if (-not (Test-Path $SdkLibDir)) {
    New-Item -ItemType Directory -Path $SdkLibDir -Force | Out-Null
}

$dllPath = "C:\Windows\System32\vulkan-1.dll"
if (-not (Test-Path $dllPath)) {
    Write-Error "Driver Vulkan host non trovato in $dllPath"
}

Write-Host "Generazione file di importazione Vulkan da $dllPath..." -ForegroundColor Cyan

# Trova llvm-dlltool nel toolchain o nel sistema
$dlltool = "llvm-dlltool"
if (Test-Path "C:\Users\mstmh\toolchain\llvm-mingw-20260616-ucrt-aarch64\bin\llvm-dlltool.exe") {
    $dlltool = "C:\Users\mstmh\toolchain\llvm-mingw-20260616-ucrt-aarch64\bin\llvm-dlltool.exe"
}

$defPath = Join-Path $SdkLibDir "vulkan-1.def"
$aPath = Join-Path $SdkLibDir "libvulkan-1.a"
$libPath = Join-Path $SdkLibDir "vulkan-1.lib"

if (Test-Path $defPath) {
    & $dlltool -m arm64 -d $defPath -l $aPath
    & $dlltool -m arm64 -d $defPath -l $libPath
    Write-Host "Librerie Vulkan ARM64 create con successo in $SdkLibDir" -ForegroundColor Green
} else {
    Write-Host "File vulkan-1.def pronto in $SdkLibDir" -ForegroundColor Yellow
}