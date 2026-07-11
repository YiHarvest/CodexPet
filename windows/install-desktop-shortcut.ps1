$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$shortcutPath = Join-Path ([Environment]::GetFolderPath('Desktop')) 'Codex Pet.lnk'
$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = 'powershell.exe'
$shortcut.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$root\windows\codex-desktop-pet.ps1`""
$shortcut.WorkingDirectory = $root
$shortcut.IconLocation = "$env:SystemRoot\System32\shell32.dll,44"
$shortcut.Save()
Write-Host "Desktop shortcut installed: $shortcutPath"
