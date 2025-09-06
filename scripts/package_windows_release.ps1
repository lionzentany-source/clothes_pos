<#
.SYNOPSIS
  Package a Windows release build of Clothes POS (strip debug symbols optionally) and produce a zip + checksum.

.USAGE
  powershell -ExecutionPolicy Bypass -File scripts/package_windows_release.ps1 [-Version 1.0.2+4] [-StripDebug]

.NOTES
  Expects you already ran: flutter build windows --release
#>
param(
  [string]$Version,
  [switch]$StripDebug
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Infer version from pubspec if not supplied
if (-not $Version) {
  $pubLine = Select-String -Path 'pubspec.yaml' -Pattern '^version:' | Select-Object -First 1
  if (-not $pubLine) { throw 'Cannot infer version (no version: line in pubspec.yaml). Provide -Version.' }
  $Version = ($pubLine -split 'version:\s*')[1].Trim()
}

$safeVersion = $Version -replace '\+','_'
$releaseDir = Join-Path 'build/windows/x64/runner/Release' ''
if (-not (Test-Path $releaseDir)) { throw "Release directory not found: $releaseDir (build first)." }

# Copy README template
$readmeTemplate = 'windows/RELEASE_README.txt'
if (Test-Path $readmeTemplate) {
  Copy-Item $readmeTemplate -Destination (Join-Path $releaseDir 'README.txt') -Force
}
else {
  Write-Warning 'Template README not found. Skipping copy.'
}

if ($StripDebug) {
  Write-Host '[Strip] Removing debug symbols (*.pdb, *.lib, *.exp)...'
  Get-ChildItem $releaseDir -Include *.pdb,*.lib,*.exp -File -ErrorAction SilentlyContinue | ForEach-Object { Remove-Item $_ -Force }
}

# Output zip path
$zipOutDir = 'build/windows'
if (-not (Test-Path $zipOutDir)) { New-Item -ItemType Directory -Path $zipOutDir | Out-Null }
$zipPath = Join-Path $zipOutDir ("clothes_pos_windows_${safeVersion}.zip")

if (Test-Path $zipPath) { Remove-Item $zipPath -Force }

Write-Host "[Zip] Creating $zipPath ..."
Compress-Archive -Path (Join-Path $releaseDir '*') -DestinationPath $zipPath -CompressionLevel Optimal

$len = (Get-Item $zipPath).Length

# SHA256 checksum
$sha = (Get-FileHash -Path $zipPath -Algorithm SHA256).Hash
Set-Content -Path ($zipPath + '.sha256') -Value "$sha  $(Split-Path $zipPath -Leaf)"

Write-Host "Done." -ForegroundColor Green
Write-Host ("Zip Size: {0:N0} bytes" -f $len)
Write-Host "SHA256: $sha"
Write-Host 'Package ready.'
