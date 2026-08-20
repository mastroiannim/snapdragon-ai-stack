# download_models.ps1
# Script per scaricare e predisporre i modelli GGUF ottimizzati per Snapdragon X

$RepoRoot = Split-Path $PSScriptRoot -Parent
$ModelsDir = Join-Path $RepoRoot "models"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " ?? Download Modelli GGUF per Snapdragon X2 Elite" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

New-Item -ItemType Directory -Path (Join-Path $ModelsDir "Qwen3-8B") -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $ModelsDir "Qwen3.8-27B") -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $ModelsDir "Muse-Glimmer-30B") -Force | Out-Null

Write-Host "1. Qwen3-8B-128K (4.45 GB) -> unsloth/Qwen3-8B-128K-GGUF" -ForegroundColor Yellow
Write-Host "2. Qwen3.8-27B (15.2 GB)   -> IvanKrastevAdventics/Qwen3.8-27B-AWQ-INT4-Q4_0-GGUF" -ForegroundColor Yellow
Write-Host "3. Muse-Glimmer-30B Vision -> Muse-Glimmer-30B-Q4_K_M.gguf" -ForegroundColor Yellow
Write-Host "==========================================================" -ForegroundColor Cyan