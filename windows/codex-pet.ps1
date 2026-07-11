param(
    [ValidateSet('show', 'hide', 'toggle', 'status')]
    [string]$Action = 'show',
    [ValidateRange(0.25, 2.0)]
    [double]$Scale = 0.75
)

$ErrorActionPreference = 'Stop'
$stateDir = Join-Path $env:LOCALAPPDATA 'CodexPet'
$pidFile = Join-Path $stateDir 'desktop-pet.pid'

function Get-PetProcess {
    if (-not (Test-Path -LiteralPath $pidFile)) { return $null }
    $savedProcessId = Get-Content -LiteralPath $pidFile -Raw
    try { return Get-Process -Id $savedProcessId.Trim() -ErrorAction Stop } catch { Remove-Item -Force $pidFile; return $null }
}

function Show-Pet {
    $process = Get-PetProcess
    if ($null -ne $process) { Write-Host "Codex Pet is already visible (PID $($process.Id))."; return }
    New-Item -ItemType Directory -Force -Path $stateDir | Out-Null
    $script = Join-Path $PSScriptRoot 'desktop_pet.ps1'
    $process = Start-Process -FilePath 'powershell.exe' -WindowStyle Hidden -PassThru -ArgumentList @(
        '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$script`"", '-Scale', $Scale
    )
    $process.Id | Set-Content -NoNewline -LiteralPath $pidFile
    Write-Host 'Codex Pet is visible. Drag it with the left mouse button.'
}

function Hide-Pet {
    $process = Get-PetProcess
    if ($null -eq $process) { Write-Host 'Codex Pet is not running.'; return }
    Stop-Process -Id $process.Id -Force
    Remove-Item -Force $pidFile -ErrorAction SilentlyContinue
    Write-Host 'Codex Pet was hidden.'
}

switch ($Action) {
    'show' { Show-Pet }
    'hide' { Hide-Pet }
    'toggle' { if ($null -ne (Get-PetProcess)) { Hide-Pet } else { Show-Pet } }
    'status' { $process = Get-PetProcess; if ($null -eq $process) { 'hidden' } else { "visible (PID $($process.Id))" } }
}
