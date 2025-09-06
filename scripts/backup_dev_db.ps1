# Backup dev sqlite database used by the app (Windows PowerShell)
# Usage: .\backup_dev_db.ps1 -OutDir .\backups
param(
    [string]$OutDir = "./backups",
    [string]$DbName = "clothes_pos.db"
)

# Resolve .dart_tool path from repo root
$cwd = Resolve-Path -LiteralPath .
$srcPath = Join-Path $cwd ".dart_tool\sqflite_common_ffi\databases\$DbName"
if (-not (Test-Path $srcPath)) {
    Write-Error "Database file not found at $srcPath"
    exit 1
}

if (-not (Test-Path $OutDir)) {
    New-Item -ItemType Directory -Path $OutDir | Out-Null
}

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$dest = Join-Path (Resolve-Path $OutDir) "$($DbName)_$timestamp.db"

# Copy with retry in case file is locked briefly
$maxAttempts = 5
for ($i = 1; $i -le $maxAttempts; $i++) {
    try {
        Copy-Item -Path $srcPath -Destination $dest -Force
        Write-Host "Backup created: $dest"
        exit 0
    }
    catch {
        Write-Warning "Attempt ${i}: Failed to copy database - ${($_.Exception.Message)}"
        Start-Sleep -Seconds (2 * $i)
    }
}

Write-Error "Failed to create backup after $maxAttempts attempts"
exit 2
