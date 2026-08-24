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
$dlltool = $null
$toolchainDirs = @(
    (Join-Path $RepoRoot "toolchain"),
    (Join-Path $env:USERPROFILE "toolchain")
)

foreach ($tc in $toolchainDirs) {
    if (Test-Path $tc) {
        $candidate = Get-ChildItem -Path $tc -Filter "llvm-mingw*" -Directory -ErrorAction SilentlyContinue |
            ForEach-Object { Join-Path $_.FullName "bin\llvm-dlltool.exe" } |
            Where-Object { Test-Path $_ } |
            Select-Object -First 1
        if ($candidate) {
            $dlltool = $candidate
            break
        }
    }
}

$dlltoolAvailable = $false
if ($dlltool -and (Test-Path $dlltool)) {
    $dlltoolAvailable = $true
} elseif ($dlltool -and (Get-Command $dlltool -ErrorAction SilentlyContinue)) {
    $dlltoolAvailable = $true
}

$defPath = Join-Path $SdkLibDir "vulkan-1.def"
$aPath = Join-Path $SdkLibDir "libvulkan-1.a"
$libPath = Join-Path $SdkLibDir "vulkan-1.lib"

if (Test-Path $defPath) {
    if ($dlltoolAvailable) {
        & $dlltool -m arm64 -d $defPath -l $aPath
        & $dlltool -m arm64 -d $defPath -l $libPath
        Write-Host "Librerie Vulkan ARM64 create con successo in $SdkLibDir" -ForegroundColor Green
    } elseif ((Test-Path $aPath) -and (Test-Path $libPath)) {
        Write-Host "Librerie Vulkan ARM64 pre-generate gia presenti in $SdkLibDir" -ForegroundColor Green
    } else {
        Write-Host "llvm-dlltool non trovato nel sistema. Esegui scripts\setup_toolchain.ps1 per installarlo." -ForegroundColor Yellow
    }
} else {
    Write-Host "File vulkan-1.def non trovato in $SdkLibDir" -ForegroundColor Yellow
}