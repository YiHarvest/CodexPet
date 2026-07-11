param([ValidateRange(0.25, 2.0)][double]$Scale = 0.75)

& (Join-Path $PSScriptRoot 'codex-pet.ps1') show -Scale $Scale
