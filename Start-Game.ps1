param([switch]$Check)
$ErrorActionPreference = 'Stop'
$gameRoot = $PSScriptRoot
$godotExe = $null
$command = Get-Command godot, godot4 -ErrorAction SilentlyContinue | Select-Object -First 1
if ($command) { $godotExe = $command.Source }
if (-not $godotExe) {
    $parentFolder = Split-Path -Parent $gameRoot
    $candidates = Get-ChildItem -LiteralPath $parentFolder -Filter 'Godot*' -ErrorAction SilentlyContinue
    foreach ($candidate in $candidates) {
        if ($candidate.PSIsContainer) {
            $found = Get-ChildItem -LiteralPath $candidate.FullName -Filter 'Godot*_win64.exe' -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -notlike '*console*' } | Select-Object -First 1
            if ($found) { $godotExe = $found.FullName; break }
        } elseif ($candidate.Extension -eq '.exe' -and $candidate.Name -notlike '*console*') {
            $godotExe = $candidate.FullName
            break
        }
    }
}
if (-not $godotExe) {
    Write-Host 'Godot 4 was not found. Import project.godot in Godot, then press F5.'
    exit 1
}
if ($Check) {
    Write-Output $godotExe
    exit 0
}
# This is the interactive game window, intentionally visible to the player.
Start-Process -FilePath $godotExe -WorkingDirectory $gameRoot -ArgumentList @('--path', ('"' + $gameRoot + '"'))
