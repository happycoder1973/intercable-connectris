<#
.SYNOPSIS
    Deaktiviert den Kiosk-Modus und stellt die normale Windows-Shell wieder her.
.DESCRIPTION
    1. Entfernt die Custom Shell-Konfiguration fuer den Kiosk-Benutzer.
    2. Setzt Explorer.exe als Standard-Shell.
    3. Deaktiviert die Keyboard-Filter-Sperren.
    4. Revertiert die Registry-Einschraenkungen fuer Strg+Alt+Entf.
.NOTES
    Dieses Skript erfordert Administratorrechte.
#>

$ErrorActionPreference = "Stop"

# 1. Administrator-Rechte pruefen
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (!$isAdmin) {
    Write-Error "Dieses Skript MUSS mit Administratorrechten (Als Administrator ausfuehren) gestartet werden!"
    Exit 1
}

$KioskUsername = "KioskUser"

Write-Host "=========================================" -ForegroundColor Green
Write-Host "   INTERCABLE CONNECTRIS KIOSK REVERT    " -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green

# 2. SID des Kiosk-Benutzers ermitteln
$UserSID = $null
try {
    $UserSID = (Get-LocalUser -Name $KioskUsername -ErrorAction SilentlyContinue).SID.Value
}
catch {
    Write-Host "Kiosk-Benutzer '$KioskUsername' wurde nicht gefunden. Revert wird fuer Standard-Einstellungen durchgefuehrt." -ForegroundColor Yellow
}

# 3. Custom Shell fuer den Kiosk-Benutzer entfernen
$WmiNamespace = "root\standardcimv2\embedded"
try {
    $ShellLauncher = [wmiclass]"\\localhost\$WmiNamespace:WESL_UserSetting"
    
    if ($UserSID) {
        Write-Host "Entferne Custom Shell fuer $KioskUsername ($UserSID)..." -ForegroundColor Cyan
        # RemoveCustomShell entfernt die Shell-Zuweisung fuer diese SID
        $ShellLauncher.RemoveCustomShell($UserSID) | Out-Null
    }
    
    # Shell Launcher global deaktivieren
    $ShellLauncher.SetEnabled($false) | Out-Null
    Write-Host "Shell Launcher erfolgreich deaktiviert." -ForegroundColor Green
}
catch {
    Write-Warning "Fehler beim Deaktivieren des Shell Launchers via WMI: $_"
}

# 4. Keyboard Filter wieder freigeben
Write-Host "`nGebe Tastenkombinationen im Keyboard Filter frei..." -ForegroundColor Cyan
try {
    # Alt+Tab freigeben
    $AltTab = Get-CimInstance -Namespace $WmiNamespace -ClassName WEKF_PredefinedKey -Filter "Id = 'AltTab'"
    if ($AltTab) {
        $AltTab.Enabled = $false
        Set-CimInstance -InputObject $AltTab
        Write-Host "Alt+Tab freigegeben." -ForegroundColor Green
    }
    
    # Alt+F4 freigeben
    $AltF4 = Get-CimInstance -Namespace $WmiNamespace -ClassName WEKF_PredefinedKey -Filter "Id = 'AltF4'"
    if ($AltF4) {
        $AltF4.Enabled = $false
        Set-CimInstance -InputObject $AltF4
        Write-Host "Alt+F4 freigegeben." -ForegroundColor Green
    }
    
    # Windows-Tasten freigeben
    $WinKey = Get-CimInstance -Namespace $WmiNamespace -ClassName WEKF_PredefinedKey -Filter "Id = 'Windows'"
    if ($WinKey) {
        $WinKey.Enabled = $false
        Set-CimInstance -InputObject $WinKey
        Write-Host "Windows-Taste freigegeben." -ForegroundColor Green
    }
}
catch {
    Write-Warning "Keyboard Filter WMI-Klassen konnten nicht modifiziert werden."
}

# 5. Registry-Richtlinien zuruecksetzen
if ($UserSID) {
    Write-Host "`nRegistry-Richtlinien zuruecksetzen..." -ForegroundColor Cyan
    $RegPath = "Registry::HKEY_USERS\$UserSID\Software\Microsoft\Windows\CurrentVersion\Policies\System"
    
    try {
        $UserHivePath = "C:\Users\$KioskUsername\NTUSER.DAT"
        $HiveLoaded = $false
        
        if (Test-Path $UserHivePath) {
            Write-Host "Lade Kiosk-User Registry Hive..." -ForegroundColor Gray
            reg load "HKU\KioskUserTemp" $UserHivePath | Out-Null
            $RegPath = "Registry::HKEY_USERS\KioskUserTemp\Software\Microsoft\Windows\CurrentVersion\Policies\System"
            $HiveLoaded = $true
        }
        
        if (Test-Path $RegPath) {
            # Richtlinien entfernen oder auf 0 setzen
            Remove-ItemProperty -Path $RegPath -Name "DisableTaskMgr" -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $RegPath -Name "DisableLockWorkstation" -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $RegPath -Name "DisableChangePassword" -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $RegPath -Name "HideFastUserSwitching" -ErrorAction SilentlyContinue
            Write-Host "Registry-Richtlinien erfolgreich geloescht." -ForegroundColor Green
        } else {
            Write-Host "Keine Registry-Richtlinien zum Zuruecksetzen gefunden." -ForegroundColor Yellow
        }
        
        if ($HiveLoaded) {
            Write-Host "Entlade Kiosk-User Registry Hive..." -ForegroundColor Gray
            [GC]::Collect()
            [GC]::WaitForPendingFinalizers()
            reg unload "HKU\KioskUserTemp" | Out-Null
        }
    }
    catch {
        Write-Warning "Fehler beim Zuruecksetzen der Registry-Richtlinien: $_"
    }
}

# 6. Optional: Kiosk-Benutzer loeschen
Write-Host "`nMoechten Sie den Kiosk-Benutzer '$KioskUsername' komplett loeschen?" -ForegroundColor Yellow
Write-Host "Falls ja, fuehren Sie folgenden Befehl manuell in einer Admin-PowerShell aus:" -ForegroundColor Gray
Write-Host "Remove-LocalUser -Name '$KioskUsername'" -ForegroundColor White

Write-Host "`n=========================================" -ForegroundColor Green
Write-Host "Kiosk-Revert erfolgreich abgeschlossen!" -ForegroundColor Green
Write-Host "Beim naechsten Login startet wieder die Standard-Explorer-Shell." -ForegroundColor Yellow
Write-Host "=========================================" -ForegroundColor Green
