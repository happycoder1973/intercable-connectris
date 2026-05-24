# Windows 11 Kiosk-Modus und Godot 4 Integration

Dieses Dokument beschreibt die Optionen zur Einrichtung eines sicheren Kiosk-Betriebs unter Windows 11 für das Projekt **Intercable Connectris**. Es umfasst die Betriebssystem-Konfiguration (Shell Launcher v2, Keyboard Filter, Gruppenrichtlinien) sowie das Godot-seitige Fenster-, Fokus- und Input-Management.

---

## 1. Windows 11 Kiosk-Modus: Shell Launcher v2

Für klassische Win32-Anwendungen (wie in Godot exportierte EXEs) ist der standardmäßige Windows 11 Kiosk-Modus ("Assigned Access" für UWP-Apps) ungeeignet. Stattdessen wird **Shell Launcher v2** verwendet. Dieser ersetzt die Standard-Windows-Shell (`explorer.exe`) für einen dedizierten Kiosk-Benutzer durch die ausführbare Datei des Spiels.

### Vorteile von Shell Launcher v2:
* **Kein Desktop-Zugriff:** Der Benutzer sieht weder Taskleiste, Startmenü noch den Desktop.
* **Automatischer App-Neustart:** Wenn das Spiel abstürzt oder geschlossen wird, startet Windows es automatisch neu.
* **Benutzerabhängig:** Administratoren können sich weiterhin normal anmelden und erhalten den regulären Windows Explorer.

---

## 2. Automatisierung via PowerShell: `kiosk-setup.ps1`

Das folgende PowerShell-Skript konfiguriert den Shell Launcher v2 und richtet einen Kiosk-Benutzer ein. 

> [!WARNING]
> Dieses Skript konfiguriert tiefgreifende Systemeinstellungen. Es muss in einer PowerShell mit **Administratorrechten** auf einer Windows 11 Enterprise-, Education- oder IoT-Enterprise-Edition ausgeführt werden. Testen Sie es niemals auf einem Produktivsystem, ohne ein alternatives Administrator-Konto für den Notfall bereitzuhalten!

```powershell
<#
.SYNOPSIS
    Konfiguriert den Windows 11 Kiosk-Modus (Shell Launcher v2) für Intercable Connectris.
.DESCRIPTION
    1. Aktiviert das Shell Launcher Feature.
    2. Erstellt einen lokalen Standardbenutzer "KioskUser".
    3. Konfiguriert die WMI-Klasse WESL_UserSetting, um die Godot-EXE als Shell zu setzen.
    4. Setzt das Verhalten bei App-Exit (Automatischer Neustart).
#>

# 1. Sicherstellen, dass das Skript als Administrator läuft
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (!$isAdmin) {
    Write-Error "Dieses Skript muss mit Administratorrechten ausgeführt werden!"
    Exit
}

# Konfigurationsvariablen
$KioskUsername = "KioskUser"
$KioskPassword = "ConnectrisPassword123!"
$AppPath = "C:\Connectris\connectris.exe" # Pfad zur Godot Single-EXE

# 2. Shell Launcher Feature aktivieren (erfordert Neustart, falls nicht installiert)
Write-Host "Aktiviere Windows-Feature: Shell Launcher..." -ForegroundColor Cyan
$FeatureStatus = Get-WindowsOptionalFeature -Online -FeatureName Client-EmbeddedShellLauncher
if ($FeatureStatus.State -ne "Enabled") {
    Enable-WindowsOptionalFeature -FeatureName Client-DeviceLockdown,Client-EmbeddedShellLauncher -Online -NoRestart
    Write-Host "Feature wurde aktiviert. Ein Systemneustart wird empfohlen." -ForegroundColor Yellow
}

# 3. Kiosk-Benutzerkonto erstellen
Write-Host "Erstelle Kiosk-Benutzer '$KioskUsername'..." -ForegroundColor Cyan
if (!(Get-LocalUser -Name $KioskUsername -ErrorAction SilentlyContinue)) {
    $PasswordSecure = ConvertTo-SecureString $KioskPassword -AsPlainText -Force
    New-LocalUser -Name $KioskUsername -Password $PasswordSecure -Description "Kiosk-Konto fuer Connectris" -PasswordNeverExpires $true -UserMayNotChangePassword $true | Out-Null
    # Benutzer zur Gruppe der Standardbenutzer hinzufügen (nicht Admin!)
    Add-LocalGroupMember -Group "Benutzer" -Member $KioskUsername
    Write-Host "Benutzer erfolgreich erstellt." -ForegroundColor Green
} else {
    Write-Host "Benutzer existiert bereits. Überspringe Erstellung." -ForegroundColor Yellow
}

# SID des Kiosk-Benutzers ermitteln
$UserSID = (Get-LocalUser -Name $KioskUsername).SID.Value

# 4. WMI-Schnittstelle für Shell Launcher v2 konfigurieren
Write-Host "Konfiguriere Shell Launcher v2..." -ForegroundColor Cyan
$WmiNamespace = "root\standardcimv2\embedded"
$ShellLauncher = [wmiclass]"\\localhost\$WmiNamespace:WESL_UserSetting"

# Shell Launcher aktivieren
$ShellLauncher.SetEnabled($true) | Out-Null

# Konfiguration für den Kiosk-Benutzer setzen:
# Parameter: SID, PathToShell, DefaultAction, CustomAction, RestartClass
# DefaultAction 0 = App neu starten, wenn sie sich schließt.
$ShellLauncher.SetCustomShell($UserSID, $AppPath, 0, 0, 0) | Out-Null

# Explorer als Default-Shell für alle anderen Benutzer (z.B. Admins) sicherstellen
$ShellLauncher.SetDefaultShell("explorer.exe", 0) | Out-Null

Write-Host "Shell Launcher erfolgreich für $KioskUsername konfiguriert." -ForegroundColor Green
Write-Host "Bitte starten Sie das System neu und melden Sie sich als '$KioskUsername' an." -ForegroundColor Green
```

---

## 3. Tastatur-Filterung (Alt+Tab & Shortcuts sperren)

Shell Launcher v2 verhindert zwar den Zugriff auf den Explorer, fängt jedoch System-Shortcuts wie **Alt+Tab**, **Alt+F4** oder die **Windows-Taste** nicht automatisch ab. Hierzu muss der **Keyboard Filter** aktiviert werden.

### Aktivierung des Keyboard Filters:
1. Per Befehlszeile (Admin):
   ```cmd
   dism /online /Enable-Feature /FeatureName:Client-KeyboardFilter
   ```
2. System neu starten.

### Sperren von Shortcuts via PowerShell:
Sie können vordefinierte Tasten über die WMI-Klasse `WEKF_PredefinedKey` blockieren. Führen Sie folgendes PowerShell-Skript aus:

```powershell
$WmiNamespace = "root\standardcimv2\embedded"

# Sperre Alt+Tab
$AltTab = Get-CimInstance -Namespace $WmiNamespace -ClassName WEKF_PredefinedKey -Filter "Id = 'AltTab'"
$AltTab.Enabled = $true
Set-CimInstance -InputObject $AltTab

# Sperre Alt+F4 (Verhindert das Schließen des Spiels)
$AltF4 = Get-CimInstance -Namespace $WmiNamespace -ClassName WEKF_PredefinedKey -Filter "Id = 'AltF4'"
$AltF4.Enabled = $true
Set-CimInstance -InputObject $AltF4

# Sperre Windows-Tasten (Startmenü blockieren)
$WinKey = Get-CimInstance -Namespace $WmiNamespace -ClassName WEKF_PredefinedKey -Filter "Id = 'Windows'"
$WinKey.Enabled = $true
Set-CimInstance -InputObject $WinKey
```

### Umgang mit Strg+Alt+Entf (Ctrl+Alt+Del)
Strg+Alt+Entf wird im Windows-Kernel verarbeitet und kann aus Sicherheitsgründen **nicht** über den Keyboard Filter blockiert werden. Um den Kiosk abzusichern, müssen die Optionen auf dem Strg+Alt+Entf-Bildschirm via Gruppenrichtlinien (GPO) oder Registry deaktiviert werden:

Pfad in der Registry: `HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\System`
* `DisableTaskMgr` = 1 (Deaktiviert Task-Manager)
* `DisableLockWorkstation` = 1 (Deaktiviert PC sperren)
* `DisableChangePassword` = 1 (Deaktiviert Kennwort ändern)
* `HideFastUserSwitching` = 1 (Deaktiviert Benutzer wechseln)

---

## 4. Godot 4 Fenster- & Fokus-Management

Um eine nahtlose Kiosk-Erfahrung zu garantieren, muss die Godot-Anwendung so konfiguriert werden, dass sie den gesamten Bildschirm einnimmt und bei eventuellen OS-Meldungen den Fokus nicht verliert.

### A. Fenster-Modus im Code erzwingen
Im Kiosk-Betrieb sollte die Anwendung im **Borderless Fullscreen** (fensterloser Vollbildmodus) laufen, da dieser stabiler auf Fokuswechsel reagiert als der Exclusive Fullscreen.

```gdscript
extends Node

func _ready() -> void:
	# Fenster-Modus auf Vollbild setzen (Borderless)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	
	# Verhindern, dass das Fenster minimiert werden kann
	# (unter Windows 11 Kiosk kritisch, falls Shortcuts gedrückt werden)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, true)
```

### B. Fokus-Verlust abfangen
Falls eine Windows-Systembenachrichtigung den Fokus stiehlt, sollte sich das Spiel diesen sofort zurückholen. Dies wird über das Empfangen von System-Benachrichtigungen gelöst:

```gdscript
func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT:
			# Spiel hat den Fokus verloren
			_handle_focus_loss()
		NOTIFICATION_APPLICATION_FOCUS_IN:
			# Spiel hat den Fokus wiedererhalten
			pass

func _handle_focus_loss() -> void:
	# Versuche den Fokus sofort wiederzugreifen
	DisplayServer.window_grab_focus()
	
	# Optional: Spiel pausieren, falls Fokus-Verlust unvermeidbar war
	# get_tree().paused = true
```

---

## 5. Touch- und Controller-Input in Godot 4

Kiosk-Terminals werden meist über Touchscreens oder fest verbaute Gamepads/Arcade-Controller bedient.

### A. Touchscreen-Konfiguration
Damit die normale Godot-UI (Buttons, Slider) auf Kiosk-Touch-Displays ohne Probleme reagiert, müssen Emulationen im Projekt eingestellt werden:

1. **Projekt-Einstellungen aktivieren:**
   * Gehen Sie auf **Projekt > Projekteinstellungen** (Erweiterte Einstellungen oben rechts aktivieren).
   * Navigieren Sie zu **Input Devices > Pointing**.
   * **Emulate Mouse From Touch (An):** Übersetzt Touch-Gesten in Mausklicks. Dies ist zwingend erforderlich, damit Control-Nodes (UI) auf Fingertipps reagieren.
   * **Emulate Touch From Mouse (Aus für Produktion):** Nur für Entwickler-PCs nützlich, um Touch mit der Maus zu testen.

2. **Gestensteuerung im Code:**
   Für Wischgesten (z. B. zum Bewegen von Blöcken in Connectris) fangen Sie die spezifischen Events in `_input` ab:
   ```gdscript
   func _input(event: InputEvent) -> void:
       if event is InputEventScreenTouch:
           if event.pressed:
               print("Touch gestartet bei: ", event.position)
           else:
               print("Touch beendet.")
       
       if event is InputEventScreenDrag:
           print("Finger bewegt sich: ", event.relative)
   ```

### B. Gamepad- und Arcade-Controller-Konfiguration
1. **InputMap nutzen:**
   Tragen Sie alle Eingabe-Aktionen (z.B. `ui_left`, `ui_right`, `rotate`) in der **Input Map** (Projekteinstellungen) ein und weisen Sie ihnen sowohl die Tastatur-Tasten (Pfeiltasten, WASD) als auch die entsprechenden Gamepad-Tasten/Achsen (D-Pad, linker Analogstick) zu.
2. **Controller-Vibration (Haptisches Feedback):**
   Für ein intensiveres Kiosk-Spielerlebnis kann haptisches Feedback gegeben werden:
   ```gdscript
   # Startet die Vibration auf Controller 0 (stark: 0.5, schwach: 0.3, Dauer: 0.2s)
   Input.start_joy_vibration(0, 0.5, 0.3, 0.2)
   ```
3. **Robustheit gegen Controller-Disconnects:**
   Kiosk-Controller können beschädigt oder ausgesteckt werden. Fangen Sie diese Ereignisse ab, um das Spiel ggf. zu pausieren:
   ```gdscript
   func _ready() -> void:
       Input.joy_connection_changed.connect(_on_joy_connection_changed)

   func _on_joy_connection_changed(device_id: int, connected: bool) -> void:
       if not connected:
           print("Warnung: Controller %d getrennt!" % device_id)
           # Hier Pausenmenü oder Warnhinweis einblenden
   ```
