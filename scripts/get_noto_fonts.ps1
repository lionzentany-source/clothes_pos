# Downloads Noto Naskh Arabic fonts into assets/fonts
Param(
    [string]$OutDir = "assets/fonts"
)

$ErrorActionPreference = 'Stop'

# Ensure run from repo root
if (-not (Test-Path "$PSScriptRoot/..")) {
    Write-Error "Run this script from the project root (where pubspec.yaml lives)."
}

# Create output dir
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

$downloads = @(
    @{ Name = 'NotoNaskhArabic-Regular.ttf'; Urls = @(
            'https://raw.githubusercontent.com/google/fonts/main/ofl/notonaskharabic/static/NotoNaskhArabic-Regular.ttf',
            'https://raw.githubusercontent.com/google/fonts/main/ofl/notonaskharabic/NotoNaskhArabic-Regular.ttf',
            'https://raw.githubusercontent.com/google/fonts/main/ofl/notonaskharabic/NotoNaskhArabic%5Bwght%5D.ttf', # variable font as last resort
            'https://raw.githubusercontent.com/googlefonts/noto-fonts/main/unhinted/ttf/NotoNaskhArabic/NotoNaskhArabic-Regular.ttf'
        ) 
    },
    @{ Name = 'NotoNaskhArabic-Bold.ttf'; Urls = @(
            'https://raw.githubusercontent.com/google/fonts/main/ofl/notonaskharabic/static/NotoNaskhArabic-Bold.ttf',
            'https://raw.githubusercontent.com/google/fonts/main/ofl/notonaskharabic/NotoNaskhArabic-Bold.ttf',
            'https://raw.githubusercontent.com/googlefonts/noto-fonts/main/unhinted/ttf/NotoNaskhArabic/NotoNaskhArabic-Bold.ttf'
        ) 
    }
)

foreach ($d in $downloads) {
    $dest = Join-Path $OutDir $d.Name
    Write-Host "Downloading $($d.Name) ..."
    $ok = $false
    foreach ($url in $d.Urls) {
        $attempt = 0
        $max = 2
        while (-not $ok -and $attempt -lt $max) {
            try {
                $attempt++
                Invoke-WebRequest -Uri $url -OutFile $dest -UseBasicParsing -TimeoutSec 60
                $ok = Test-Path $dest
            }
            catch {
                if ($attempt -lt $max) {
                    Write-Warning "Attempt $attempt for $url failed. Retrying in 2s..."
                    Start-Sleep -Seconds 2
                }
            }
        }
        if ($ok) { break }
    }
    if (-not $ok) { throw "Failed to download $($d.Name). Tried: $($d.Urls -join ', ')" }
}

Write-Host "Done. Files saved under '$OutDir'."
Write-Host "Next steps:"
Write-Host "  1) Open pubspec.yaml and uncomment the 'Noto Naskh Arabic' fonts section."
Write-Host "  2) Run: flutter pub get"
Write-Host "  3) Rebuild the app."
