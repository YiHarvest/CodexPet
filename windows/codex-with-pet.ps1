param([Parameter(ValueFromRemainingArguments = $true)][string[]]$CodexArgs)

$ErrorActionPreference = 'Stop'
& (Join-Path $PSScriptRoot 'codex-pet.ps1') show
try {
    & codex @CodexArgs
    exit $LASTEXITCODE
} finally {
    & (Join-Path $PSScriptRoot 'codex-pet.ps1') hide
}
