<#
.SYNOPSIS
Starts the Intercable Connectris game for Kiosk-Mode.
#>

$ErrorActionPreference = "Stop"

$ExeName = "IntercableConnectris.exe"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$ExePath = Join-Path $ScriptDir $ExeName

if (Test-Path $ExePath) {
    Write-Host "Starting $ExeName..."
    Start-Process -FilePath $ExePath -WorkingDirectory $ScriptDir
} else {
    Write-Host "Executable $ExeName not found in $ScriptDir."
    Write-Host "Please export the project first."
}
