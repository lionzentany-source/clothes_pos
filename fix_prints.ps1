# PowerShell script to add ignore comments to all print statements in tool files
$toolDir = "tool"
$dartFiles = Get-ChildItem -Path $toolDir -Filter "*.dart" -Recurse

foreach ($file in $dartFiles) {
    $content = Get-Content $file.FullName -Raw
    if ($content -match 'print\(') {
        # Add ignore comment before print statements that don't already have one
        $updatedContent = $content -replace '(?<!// ignore: avoid_print\r?\n\s*)(\s*)print\(', '$1// ignore: avoid_print$([Environment]::NewLine)$1print('
        Set-Content -Path $file.FullName -Value $updatedContent -NoNewline
        Write-Host "Updated: $($file.FullName)"
    }
}
Write-Host "Completed fixing print statements in tool files"
