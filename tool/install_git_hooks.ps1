Param()

$repoRoot = Get-Location
$src = Join-Path $repoRoot '.githooks\pre-commit-template'
$dstDir = Join-Path $repoRoot '.git\hooks'
$dst = Join-Path $dstDir 'pre-commit'

if (!(Test-Path $src)) {
  Write-Error "Hook template not found: $src"
  exit 1
}

if (!(Test-Path $dstDir)) {
  Write-Error ".git/hooks not found. Are you in the repository root?"
  exit 1
}

Copy-Item -Path $src -Destination $dst -Force
# On Windows, make sure the file is not blocked; Git on Windows will run the script in sh if available
(Get-Item $dst).Attributes = 'Normal'
Write-Output "Installed pre-commit hook to $dst"
