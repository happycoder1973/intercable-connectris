<#
.SYNOPSIS
    Richtet den Windows 11 Kiosk-Modus (Shell Launcher v2) fuer Intercable Connectris ein.
.DESCRIPTION
    1. Aktiviert das Shell-Launcher- und Tastaturfilter-Feature.
    2. Erstellt einen lokalen Standardbenutzer "KioskUser".
    3. Konfiguriert die Godot-EXE als Shell fuer den KioskUser mit dem Parameter --kiosk.
    4. Aktiviert Tastaturfilter (Alt+Tab, Alt+F4, Windows-Taste).
    5. Konfiguriert Registry-Richtlinien zur Absicherung von Strg+Alt+Entf.
.NOTES
    Dieses Skript erfordert Administratorrechte und sollte auf einem dedizierten Kiosk-System
    ausgefuehrt werden.
#>

$ErrorActionPreference = "Stop"

# 1. Administrator-Rechte pruefen
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (!$isAdmin) {
    Write-Error "Dieses Skript MUSS mit Administratorrechten (Als Administrator ausfuehren) gestartet werden!"
    Exit 1
}

# Konfigurationsvariablen
$KioskUsername = "KioskUser"
$KioskPassword = "ConnectrisPassword123!"
$CurrentDir = Resolve-Path "$PSScriptRoot"
$AppPath = Join-Path $CurrentDir "IntercableConnectris.exe"

Write-Host "=========================================" -ForegroundColor Green
Write-Host "   INTERCABLE CONNECTRIS KIOSK SETUP     " -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green
Write-Host "Ziel-Anwendung: $AppPath" -ForegroundColor Yellow

if (!(Test-Path $AppPath)) {
    Write-Warning "Warnung: Die Spieldatei wurde unter '$AppPath' nicht gefunden!"
    Write-Warning "Bitte stellen Sie sicher, dass das Spiel vor der Kiosk-Nutzung dorthin exportiert wird."
}

# 2. Windows Features aktivieren
Write-Host "`n[1/5] Windows-Features aktivieren..." -ForegroundColor Cyan
try {
    # Shell Launcher Feature
    $ShellLauncherStatus = Get-WindowsOptionalFeature -Online -FeatureName Client-EmbeddedShellLauncher
    if ($ShellLauncherStatus.State -ne "Enabled") {
        Write-Host "Aktiviere Embedded Shell Launcher..." -ForegroundColor Yellow
        Enable-WindowsOptionalFeature -FeatureName Client-EmbeddedShellLauncher -Online -NoRestart | Out-Null
    } else {
        Write-Host "Embedded Shell Launcher ist bereits aktiviert." -ForegroundColor Green
    }

    # Keyboard Filter Feature
    $KbdFilterStatus = Get-WindowsOptionalFeature -Online -FeatureName Client-KeyboardFilter
    if ($KbdFilterStatus.State -ne "Enabled") {
        Write-Host "Aktiviere Keyboard Filter..." -ForegroundColor Yellow
        Enable-WindowsOptionalFeature -FeatureName Client-KeyboardFilter -Online -NoRestart | Out-Null
    } else {
        Write-Host "Keyboard Filter ist bereits aktiviert." -ForegroundColor Green
    }
}
catch {
    Write-Error "Fehler beim Aktivieren der Windows-Features: $_"
}

# 3. Kiosk-Benutzerkonto erstellen
Write-Host "`n[2/5] Kiosk-Benutzer '$KioskUsername' einrichten..." -ForegroundColor Cyan
if (!(Get-LocalUser -Name $KioskUsername -ErrorAction SilentlyContinue)) {
    $PasswordSecure = ConvertTo-SecureString $KioskPassword -AsPlainText -Force
    New-LocalUser -Name $KioskUsername -Password $PasswordSecure -Description "Kiosk-Konto fuer Connectris" -PasswordNeverExpires $true -UserMayNotChangePassword $true | Out-Null
    # Zur Standardbenutzer-Gruppe (Benutzer) hinzufuegen, nicht Admins
    Add-LocalGroupMember -Group "Benutzer" -Member $KioskUsername
    Write-Host "Benutzer '$KioskUsername' wurde erfolgreich erstellt." -ForegroundColor Green
} else {
    Write-Host "Benutzer '$KioskUsername' existiert bereits. Konfiguration wird aktualisiert." -ForegroundColor Yellow
}

# SID des Kiosk-Benutzers ermitteln
$UserSID = (Get-LocalUser -Name $KioskUsername).SID.Value
Write-Host "User SID: $UserSID" -ForegroundColor Gray

# 4. WMI-Schnittstelle fuer Shell Launcher v2 konfigurieren
Write-Host "`n[3/5] Shell Launcher v2 (Custom Shell) konfigurieren..." -ForegroundColor Cyan
$WmiNamespace = "root\standardcimv2\embedded"
try {
    $ShellLauncher = [wmiclass]"\\localhost\$WmiNamespace:WESL_UserSetting"
    
    # Shell Launcher global aktivieren
    $ShellLauncher.SetEnabled($true) | Out-Null
    
    # Custom Shell fuer den Kiosk-Benutzer setzen (DefaultAction 0 = App neu starten bei Exit)
    # Startet mit dem Parameter --kiosk
    $ShellPathWithArgs = """$AppPath"" --kiosk"
    $ShellLauncher.SetCustomShell($UserSID, $ShellPathWithArgs, 0, 0, 0) | Out-Null
    
    # Explorer als Standard-Shell fuer Admins sicherstellen
    $ShellLauncher.SetDefaultShell("explorer.exe", 0) | Out-Null
    
    Write-Host "Shell Launcher erfolgreich fuer $KioskUsername konfiguriert." -ForegroundColor Green
}
catch {
    Write-Error "Fehler bei der Konfiguration des Shell Launchers via WMI: $_"
}

# 5. Keyboard Filter (Tastenkombinationen sperren)
Write-Host "`n[4/5] Keyboard Filter einrichten..." -ForegroundColor Cyan
try {
    # Alt+Tab sperren
    $AltTab = Get-CimInstance -Namespace $WmiNamespace -ClassName WEKF_PredefinedKey -Filter "Id = 'AltTab'"
    if ($AltTab) {
        $AltTab.Enabled = $true
        Set-CimInstance -InputObject $AltTab
        Write-Host "Tastenkombination Alt+Tab blockiert." -ForegroundColor Green
    }
    
    # Alt+F4 sperren
    $AltF4 = Get-CimInstance -Namespace $WmiNamespace -ClassName WEKF_PredefinedKey -Filter "Id = 'AltF4'"
    if ($AltF4) {
        $AltF4.Enabled = $true
        Set-CimInstance -InputObject $AltF4
        Write-Host "Tastenkombination Alt+F4 blockiert." -ForegroundColor Green
    }
    
    # Windows-Tasten sperren
    $WinKey = Get-CimInstance -Namespace $WmiNamespace -ClassName WEKF_PredefinedKey -Filter "Id = 'Windows'"
    if ($WinKey) {
        $WinKey.Enabled = $true
        Set-CimInstance -InputObject $WinKey
        Write-Host "Windows-Taste blockiert." -ForegroundColor Green
    }
}
catch {
    Write-Warning "Keyboard Filter WMI-Klassen konnten nicht geladen werden. Ist der Keyboard Filter Dienst aktiv?"
}

# 6. Strg+Alt+Entf Absicherung via Registry
Write-Host "`n[5/5] Strg+Alt+Entf Optionen sperren..." -ForegroundColor Cyan
$RegPath = "Registry::HKEY_USERS\$UserSID\Software\Microsoft\Windows\CurrentVersion\Policies\System"

# Da die Registry fuer den Benutzer eventuell nicht geladen ist (wenn er noch nie eingeloggt war),
# schreiben wir die Werte auch in einen Registrierungspfad, der beim ersten Login geladen wird,
# oder versuchen den Pfad direkt zu erstellen.
try {
    # Versuchen, die Benutzer-Registry zu laden, falls KioskUser schon ein Profil hat
    $UserHivePath = "C:\Users\$KioskUsername\NTUSER.DAT"
    $HiveLoaded = $false
    
    if (Test-Path $UserHivePath) {
        Write-Host "Lade Kiosk-User Registry Hive..." -ForegroundColor Gray
        reg load "HKU\KioskUserTemp" $UserHivePath | Out-Null
        $RegPath = "Registry::HKEY_USERS\KioskUserTemp\Software\Microsoft\Windows\CurrentVersion\Policies\System"
        $HiveLoaded = $true
    }
    
    if (!(Test-Path $RegPath)) {
        New-Item -Path $RegPath -Force | Out-Null
    }
    
    # Richtlinien setzen
    Set-ItemProperty -Path $RegPath -Name "DisableTaskMgr" -Value 1 -Type DWord
    Set-ItemProperty -Path $RegPath -Name "DisableLockWorkstation" -Value 1 -Type DWord
    Set-ItemProperty -Path $RegPath -Name "DisableChangePassword" -Value 1 -Type DWord
    Set-ItemProperty -Path $RegPath -Name "HideFastUserSwitching" -Value 1 -Type DWord
    
    if ($HiveLoaded) {
        Write-Host "Entlade Kiosk-User Registry Hive..." -ForegroundColor Gray
        [GC]::Collect()
        [GC]::WaitForPendingFinalizers()
        reg unload "HKU\KioskUserTemp" | Out-Null
    }
    
    Write-Host "Registry-Richtlinien fuer Kiosk-Sicherheit erfolgreich angewendet." -ForegroundColor Green
}
catch {
    Write-Warning "Konnte Registry-Richtlinien fuer $KioskUsername nicht direkt anwenden: $_"
    Write-Warning "Die Absicherung greift eventuell erst nach dem ersten Login und Profilerstellung."
}

Write-Host "`n=========================================" -ForegroundColor Green
Write-Host "Kiosk-Setup erfolgreich abgeschlossen!" -ForegroundColor Green
Write-Host "Bitte starten Sie den PC neu und melden Sie sich als '$KioskUsername' an." -ForegroundColor Yellow
Write-Host "=========================================" -ForegroundColor Green
