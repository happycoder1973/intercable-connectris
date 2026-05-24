<#
.SYNOPSIS
    Automatisiert den Export und die Paketierung von Intercable Connectris.
.DESCRIPTION
    1. Exportiert das Spiel headless ueber die Godot-CLI.
    2. Kopiert alle benoetigten Kiosk-Skripte und Dokumente in ein temporaeres Verzeichnis.
    3. Erstellt ein archiviertes ZIP-Release-Paket.
#>

$ErrorActionPreference = "Stop"

# Konfiguration
$GodotPath = "Godot_Engine/Godot_v4.3-stable_mono_win64_console.exe"
$ExportPreset = '"Windows Desktop"'
$BuildDir = "build"
$TargetExe = "IntercableConnectris.exe"
$TargetPck = "IntercableConnectris.pck"
$ZipName = "IntercableConnectris_Release.zip"

Write-Host "=========================================" -ForegroundColor Green
Write-Host "   BUILD & EXPORT AUTOMATION SKRIPT      " -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green

# 1. Godot-Pfad aufloesen
$CurrentDir = Resolve-Path "$PSScriptRoot\.."
$GodotAbsolute = Join-Path $CurrentDir $GodotPath

if (!(Test-Path $GodotAbsolute)) {
    Write-Error "Godot Engine Konsolen-Executable wurde unter '$GodotAbsolute' nicht gefunden!"
    Exit 1
}

# 2. Export ausführen
Write-Host "`n[1/3] Starte Godot Headless Export..." -ForegroundColor Cyan
Push-Location $CurrentDir
try {
    # Sicherstellen, dass das Export-Verzeichnis existiert
    if (!(Test-Path $BuildDir)) {
        New-Item -ItemType Directory -Path $BuildDir | Out-Null
    }

    # Godot Export ausführen
    $Args = @("--headless", "--export-release", $ExportPreset, "$BuildDir/$TargetExe")
    Write-Host "Befehl: $GodotAbsolute $($Args -join ' ')" -ForegroundColor Gray
    
    $Process = Start-Process -FilePath $GodotAbsolute -ArgumentList $Args -Wait -NoNewWindow -PassThru
    if ($Process.ExitCode -ne 0) {
        Write-Error "Godot Export ist mit Exit-Code $($Process.ExitCode) fehlgeschlagen!"
        Exit 1
    }
    Write-Host "Export erfolgreich abgeschlossen!" -ForegroundColor Green
}
catch {
    Write-Error "Fehler waehrend des Godot-Exports: $_"
    Exit 1
}
finally {
    Pop-Location
}

# 3. Paketieren
Write-Host "`n[2/3] Bereite Release-Ordner vor..." -ForegroundColor Cyan
$TempDir = Join-Path $CurrentDir "build/temp_release"
if (Test-Path $TempDir) {
    Remove-Item -Recurse -Force $TempDir | Out-Null
}
New-Item -ItemType Directory -Path $TempDir | Out-Null

try {
    # Kopiere Hauptdateien
    Copy-Item (Join-Path $CurrentDir "$BuildDir/$TargetExe") -Destination $TempDir
    
    # Falls PCK separat exportiert wurde
    $PckPath = Join-Path $CurrentDir "$BuildDir/$TargetPck"
    if (Test-Path $PckPath) {
        Copy-Item $PckPath -Destination $TempDir
    }

    # Kopiere Kiosk-Skripte und Dokumentation
    Copy-Item (Join-Path $CurrentDir "$BuildDir/kiosk-setup.ps1") -Destination $TempDir
    Copy-Item (Join-Path $CurrentDir "$BuildDir/kiosk-revert.ps1") -Destination $TempDir
    Copy-Item (Join-Path $CurrentDir "$BuildDir/README_KIOSK.md") -Destination $TempDir

    Write-Host "`n[3/3] Erstelle ZIP-Archiv '$ZipName'..." -ForegroundColor Cyan
    $ZipDest = Join-Path $CurrentDir $ZipName
    if (Test-Path $ZipDest) {
        Remove-Item $ZipDest -Force | Out-Null
    }

    # Komprimiere Ordner
    Compress-Archive -Path "$TempDir\*" -DestinationPath $ZipDest -Force
    Write-Host "ZIP-Archiv wurde erfolgreich erstellt!" -ForegroundColor Green
}
catch {
    Write-Error "Fehler waehrend der Paketierung: $_"
}
finally {
    # Aufräumen
    if (Test-Path $TempDir) {
        Remove-Item -Recurse -Force $TempDir | Out-Null
    }
}

Write-Host "`n=========================================" -ForegroundColor Green
Write-Host "Build & Release Packaging erfolgreich!" -ForegroundColor Green
Write-Host "Datei: $ZipDest" -ForegroundColor Yellow
Write-Host "=========================================" -ForegroundColor Green
