$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$petName = "bubuyier-ref"
$sourceDir = Join-Path $repoRoot "pets\$petName\codex-v2"
$targetDir = Join-Path $HOME ".codex\pets\$petName"

if (-not (Test-Path -LiteralPath $sourceDir)) {
    throw "Pet folder not found: $sourceDir"
}

New-Item -ItemType Directory -Force -Path $targetDir | Out-Null
Copy-Item -LiteralPath (Join-Path $sourceDir "pet.json") -Destination (Join-Path $targetDir "pet.json") -Force
Copy-Item -LiteralPath (Join-Path $sourceDir "spritesheet.png") -Destination (Join-Path $targetDir "spritesheet.png") -Force

Write-Host "Installed $petName to $targetDir"
Write-Host "Restart Codex or refresh the pet picker if it is already open."
